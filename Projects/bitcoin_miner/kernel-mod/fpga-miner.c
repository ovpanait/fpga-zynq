#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/gpio/consumer.h>
#include <linux/gpio.h>
#include <linux/debugfs.h>
#include <linux/types.h>
#include <linux/delay.h>
#include <linux/kthread.h>
#include <linux/uaccess.h>

#define SPIDEV_MAJOR 153
#define N_SPI_MINORS			32	/* ... up to 256 */

static DECLARE_BITMAP(minors, N_SPI_MINORS);

struct miner_data {
	dev_t devt;
	spinlock_t spi_lock;
	struct spi_device *spi;
	struct list_head device_entry;

	struct task_struct *kthr;

	/* TX/RX buffers are NULL unless this device is open (users > 0) */
	struct mutex buf_lock;
	unsigned users;
	u8 *tx_buffer;
	u8 *rx_buffer;

	u8 need_reset;
	u8 done;
	u8 found;
	u8 can_start;
	u8 can_read;
	u32 speed_hz;
};

static LIST_HEAD(device_list);
static DEFINE_MUTEX(device_list_lock);
static unsigned bufsiz = 76;

static struct class *miner_class;

/* ------------------------------------------------------------------ */

#define WAITING 	0xA0
#define WORKING 	0xA1
#define MSG_START 	0xA2
#define GET_STATE 	0xA3
#define GET_MSG 	0xA4
#define DONE 		0xA5
#define DONE_FOUND 	0xA6

#define BYTES_NUM	76

static u8 transfer_byte(struct miner_data *data, u8 byte)
{
	int status;
	struct spi_device *spi;
	u8 ret;

	pr_debug("Entering function: %s.\n", __func__);
	pr_debug("transfer_byte: Byte: %02X", byte);

	spin_lock_irq(&data->spi_lock);
	spi = data->spi;
	spin_unlock_irq(&data->spi_lock);

	struct spi_transfer t = {
			.tx_buf		= &byte,
			.rx_buf		= &ret,
			.len		= 1,
			.speed_hz	= data->speed_hz,
	};

	status = spi_sync_transfer(spi, &t, 1);
	if (status != 0)
		pr_err("Error transferring byte");

	pr_debug("transfer_byte: ret: %02X", ret);
	pr_debug("Exiting function %s\n", __func__);

	//msleep(100);
	return ret;
} 

/* Spi packets processing logic */
/* This function runs until kthread_stop(); is called on max10_miner_release() */
static int threadfn(void *data_p)
{
	pr_debug("Entering function %s\n", __func__);

	struct miner_data *data = data_p;
	u8 val;
	u16 i, j;

	while(1) {
		
		if (kthread_should_stop())
			do_exit(0);

		/* pr_debug("Entering threadfn while"); */
		mutex_lock(&data->buf_lock);
		
		/* pr_debug("threadfn: Mutex aquired"); */
		if (data->can_start == 0 || data->can_read == 1) {
			mutex_unlock(&data->buf_lock);
			msleep(25);
			continue;
		}
		
		val = transfer_byte(data, GET_STATE);
		if (val == WAITING || val == DONE || val == 0) {
			transfer_byte(data, MSG_START);

			/* Transfer first_stage_hash */
			for (i=0, j=0; j < 32; ++i, ++j)
				transfer_byte(data, data->tx_buffer[i]);
			
			/* Transfer last 4 bytes of Merkle root */
			for (j=0; j < 4 ; ++i, ++j)
				transfer_byte(data, data->tx_buffer[i]);

			/* Transfer time */
			for (j=0; j < 4 ; ++i, ++j)
				transfer_byte(data, data->tx_buffer[i]);

			/* Transfer bits */
			for (j=0; j < 4 ; ++i, ++j)
				transfer_byte(data, data->tx_buffer[i]);

			/* Transfer previous block */
			for (j=0; j < 32; ++i, ++j)
				transfer_byte(data, data->tx_buffer[i]);
				
			do {
				if (val != DONE && val != DONE_FOUND)
					msleep(25);

				val = transfer_byte(data, GET_STATE);
			} while(val != DONE && val != DONE_FOUND);
			
			data->done = 1;
			
			if (val == DONE_FOUND) {
				transfer_byte(data, GET_MSG);
				transfer_byte(data, GET_MSG);
				
				for (i=0; i < 36; ++i)
					data->rx_buffer[i] = transfer_byte(data, 0xA7);
				
				data->found = 1;
			}
			
			data->can_read = 1;
			data->can_start = 0;
		}

		data->can_start = 0;
		mutex_unlock(&data->buf_lock);
		//msleep(1000);
	}

	pr_debug("Exiting function %s\n", __func__);

	return 0;
}

/* ------------------------------------------------------------------ */

/* Write-only message with current device setup */
static ssize_t
max10_miner_write(struct file *filp, const char __user *buf,
		size_t count, loff_t *f_pos)
{
	struct miner_data *data;
	ssize_t status = 0;
	unsigned long missing;

	pr_debug("Entering function: %s: count: %u\n", __func__, count);

	/* chipselect only toggles at start or end of operation */
	if (count > bufsiz) {
		pr_err("max10_miner_write: count > bufsiz");
		return -EMSGSIZE;
	}

	data = filp->private_data;

	mutex_lock(&data->buf_lock);

	missing = copy_from_user(data->tx_buffer, buf, count);
	if (missing != 0)
		status = -EFAULT;
	else {
		data->done = 0;
		data->found = 0;
		data->can_start = 1;
		status = count;
	}
	mutex_unlock(&data->buf_lock);

	pr_debug("Exiting function: %s: status: %d\n", __func__, status);

	return status;
}

static ssize_t
max10_miner_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	pr_debug("Entering function: %s: count: %u\n", __func__, count);

	struct miner_data *data;
	unsigned long missing;
	ssize_t status = 0;
	u8 cond;

	/* chipselect only toggles at start or end of operation */
	if (count != bufsiz) {
		pr_err("max10_miner_read: count > bufsiz");
		return -EMSGSIZE;
	}
	data = filp->private_data;

	/* Copy results to userspace */
	do {
		mutex_lock(&data->buf_lock);
		cond = data->can_read;
		mutex_unlock(&data->buf_lock);
		
		if (cond == 0)
			msleep(25);
	} while (cond == 0);
		

	/* TODO: handle all cases depending on FPGA output */
	mutex_lock(&data->buf_lock);
	
	if (data->found == 1) {
		missing = copy_to_user(buf, data->rx_buffer, BYTES_NUM);
	
		if (missing != 0)
			status = -EFAULT;
		else
			status = count;
	} else
		status = -EAGAIN;
	data->can_read = 0;
	mutex_unlock(&data->buf_lock);

	pr_debug("Exiting function: %s.\n", __func__);

	return status;
}

static int max10_miner_open(struct inode *inode, struct file *filp)
{
	struct miner_data *data;
	int status = -ENXIO;

	mutex_lock(&device_list_lock);

	pr_debug("Entering function: %s.\n", __func__);

	list_for_each_entry(data, &device_list, device_entry) {
		if (data->devt == inode->i_rdev) {
			status = 0;
			break;
		}
	}

	if (status) {
		pr_debug("data: nothing for minor %d\n", iminor(inode));
		goto err_find_dev;
	}

	if (!data->tx_buffer) {
		data->tx_buffer = kmalloc(bufsiz, GFP_KERNEL);
		if (!data->tx_buffer) {
			dev_dbg(&data->spi->dev, "open/ENOMEM\n");
			status = -ENOMEM;
			goto err_find_dev;
		}
	}

	if (!data->rx_buffer) {
		data->rx_buffer = kmalloc(bufsiz, GFP_KERNEL);
		if (!data->rx_buffer) {
			dev_dbg(&data->spi->dev, "open/ENOMEM\n");
			status = -ENOMEM;
			goto err_alloc_rx_buf;
		}
	}

	data->done = 0;
	data->found = 0;
	data->can_start = 0;
	data->can_read = 0;
	data->kthr = kthread_run(threadfn, data, "miner_worker");
	if (IS_ERR(data->kthr)) {
		pr_err("Could not create kernel thread\n");
		status = PTR_ERR(data->kthr);
		goto err_alloc_rx_buf;
	}

	data->users++;
	filp->private_data = data;
	nonseekable_open(inode, filp);

	mutex_unlock(&device_list_lock);

	pr_debug("Exiting function: %s.\n", __func__);
	return 0;

err_alloc_rx_buf:
	kfree(data->tx_buffer);
	data->tx_buffer = NULL;
err_find_dev:
	mutex_unlock(&device_list_lock);
	return status;
}

static int max10_miner_release(struct inode *inode, struct file *filp)
{
	pr_debug("Entering function: %s.\n", __func__);

	struct miner_data *data;

	pr_debug("max10_miner_release: before mutex");
	mutex_lock(&device_list_lock);
	pr_debug("max10_miner_release: took mutex");
	data = filp->private_data;
	filp->private_data = NULL;

	/* last close? */
	pr_debug("max10_miner_release: before --");
	data->users--;
	if (!data->users) {
		int dofree;
		
		pr_debug("max10_miner_release: in !data->users");
		/* Kill spi worker thread */
		kthread_stop(data->kthr);
		
		pr_debug("max10_miner_release: after kthread_stop");
		/* Deallocate resources */
		kfree(data->tx_buffer);
		data->tx_buffer = NULL;

		kfree(data->rx_buffer);
		data->rx_buffer = NULL;

		pr_debug("max10_miner_release: before spinlock");
		spin_lock_irq(&data->spi_lock);
		if (data->spi)
			data->speed_hz = data->spi->max_speed_hz;

		/* ... after we unbound from the underlying device? */
		dofree = (data->spi == NULL);
		spin_unlock_irq(&data->spi_lock);
		pr_debug("max10_miner_release: after spin_lock");

		if (dofree)
			kfree(data);
	}
	mutex_unlock(&device_list_lock);

	pr_debug("Exiting function: %s.\n", __func__);

	return 0;
}

static const struct file_operations max10_miner_fops = {
	.owner =	THIS_MODULE,

	.write =	max10_miner_write,
	.read =		max10_miner_read,
	.open =		max10_miner_open,
	.release =	max10_miner_release,
	.llseek =	no_llseek,
};

/* ------------------------------------------------------------------ */

static int max10_miner_probe(struct spi_device *spi)
{
	struct miner_data *data;
	int	ret;
	unsigned long minor;

	pr_debug("Entering function: %s.\n", __func__);

	/* Allocate driver data */
	data = kzalloc(sizeof(*data), GFP_KERNEL);
	if (!data)
		return -ENOMEM;

	/* Initialize the driver data */
	data->spi = spi;
	spin_lock_init(&data->spi_lock);
	mutex_init(&data->buf_lock);

	INIT_LIST_HEAD(&data->device_entry);

	/* If we can allocate a minor number, hook up this device.
	 * Reusing minors is fine so long as udev or mdev is working.
	 */
	mutex_lock(&device_list_lock);
	minor = find_first_zero_bit(minors, N_SPI_MINORS);
	if (minor < N_SPI_MINORS) {
		struct device *dev;

		data->devt = MKDEV(SPIDEV_MAJOR, minor);
		dev = device_create(miner_class, &spi->dev, data->devt,
				    data, "miner%d.%d",
				    spi->master->bus_num, spi->chip_select);
		ret = PTR_ERR_OR_ZERO(dev);
	} else {
		dev_dbg(&spi->dev, "no minor number available!\n");
		ret = -ENODEV;
	}
	if (ret == 0) {
		set_bit(minor, minors);
		list_add(&data->device_entry, &device_list);
	}
	mutex_unlock(&device_list_lock);

	data->speed_hz = spi->max_speed_hz;

	if (ret == 0)
		spi_set_drvdata(spi, data);
	else
		kfree(data);

	return ret;
}

static int max10_miner_remove(struct spi_device *spi)
{
	struct miner_data *data = spi_get_drvdata(spi);

	pr_debug("Entering function: %s.\n", __func__);

	/* make sure ops on existing fds can abort cleanly */
	spin_lock_irq(&data->spi_lock);
	data->spi = NULL;
	spin_unlock_irq(&data->spi_lock);

	/* prevent new opens */
	mutex_lock(&device_list_lock);
	device_destroy(miner_class, data->devt);
	clear_bit(MINOR(data->devt), minors);
	if (data->users == 0)
		kfree(data);
	mutex_unlock(&device_list_lock);

	return 0;
}

#ifdef CONFIG_OF
static const struct of_device_id miner_dt_ids[] = {
	{ .compatible = "ovidiu,max10_miner" },
	{},
};
MODULE_DEVICE_TABLE(of, miner_dt_ids);
#endif

static struct spi_driver max10_miner_spi_driver = {
	.driver = {
		.name = "max10_miner",
		.of_match_table = of_match_ptr(miner_dt_ids),
		.owner = THIS_MODULE,
	},
	.probe = max10_miner_probe,
	.remove = max10_miner_remove,
};

static int __init max10_miner_init(void)
{
	int ret;

	pr_debug("Entering function: %s.\n", __func__);

	ret = register_chrdev(SPIDEV_MAJOR, "spi", &max10_miner_fops);
	if (ret < 0) {
		pr_err("Failed to register character device.\n");
		return ret;
	}

	miner_class = class_create(THIS_MODULE, "miner");
	if (IS_ERR(miner_class)) {
		pr_err("Failed to create miner class");
		unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
		return PTR_ERR(miner_class);
	}

	ret = spi_register_driver(&max10_miner_spi_driver);
	if (ret < 0) {
		pr_err("Failed to register to spi core.\n");
		class_destroy(miner_class);
		unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
	}

	pr_debug("Exiting function: %s.\n", __func__);
	return ret;
}
module_init(max10_miner_init);

static void __exit max10_miner_exit(void)
{
	pr_debug("Entering function: %s.\n", __func__);

	spi_unregister_driver(&max10_miner_spi_driver);
	class_destroy(miner_class);
	unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
  
	pr_debug("Exiting function: %s.\n", __func__);
}
module_exit(max10_miner_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ovidiu Panait");
MODULE_DESCRIPTION("SPI driver for MAX10 based fpga miner.");
