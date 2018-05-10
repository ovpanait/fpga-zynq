#include <linux/module.h>
#include <linux/spi/spi.h>
#include <linux/gpio/consumer.h>
#include <linux/gpio.h>
#include <linux/debugfs.h>
#include <linux/types.h>

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
	u32	speed_hz;
};

static LIST_HEAD(device_list);
static DEFINE_MUTEX(device_list_lock);

static struct class *miner_class;

/* ------------------------------------------------------------------ */

static ssize_t
max10_miner_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	pr_debug("Entering function: %s.\n", __func__);
	
	pr_debug("Exiting function: %s.\n", __func__);

	return 0;
}

/* Write-only message with current device setup */
static ssize_t
max10_miner_write(struct file *filp, const char __user *buf,
		size_t count, loff_t *f_pos)
{
	pr_debug("Entering function: %s.\n", __func__);
	
	pr_debug("Exiting function: %s.\n", __func__);

	return 0;
}

static int max10_miner_open(struct inode *inode, struct file *filp)
{
	pr_debug("Entering function: %s.\n", __func__);
	
	pr_debug("Exiting function: %s.\n", __func__);
	return 0;
}

static int max10_miner_release(struct inode *inode, struct file *filp)
{
	pr_debug("Entering function: %s.\n", __func__);
	
	pr_debug("Exiting function: %s.\n", __func__);
	return 0;
}

static const struct file_operations max10_miner_fops = {
	.owner =	THIS_MODULE,
	/* REVISIT switch to aio primitives, so that userspace
	 * gets more complete API coverage.  It'll simplify things
	 * too, except for the locking.
	 */
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

	ret = register_chrdev(SPIDEV_MAJOR, "spi", &max10_miner_fops);
	if (ret < 0) {
		pr_err("Failed to register character device.\n");
		return ret;
	}

	miner_class = class_create(THIS_MODULE, "miner");
	if (IS_ERR(miner_class)) {
		pr_error("Failed to create miner class");
		unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
		return PTR_ERR(miner_class);
	}

	ret = spi_register_driver(&max10_miner_spi_driver);
	if (ret < 0) {
		pr_err("Failed to register to spi core.\n");
		class_destroy(miner_class);
		unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
	}

	return ret;
}
module_init(max10_miner_init);

static void __exit max10_miner_exit(void)
{
	pr_debug("Exiting function: %s.\n", __func__);

	spi_unregister_driver(&max10_miner_spi_driver);
	class_destroy(miner_class);
	unregister_chrdev(SPIDEV_MAJOR, max10_miner_spi_driver.driver.name);
  
	pr_debug("Exiting function: %s.\n", __func__);
}
module_exit(max10_miner_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ovidiu Panait");
MODULE_DESCRIPTION("SPI driver for MAX10 based fpga miner.");
