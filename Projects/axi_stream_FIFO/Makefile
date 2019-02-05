IP_REPO_DIR = "ip_repo"
PROJ_DIR = "test_proj"
SIM_DIR = "outputs"

ifndef VIVADO_SDK
$(error "VIVADO_SDK is not set. Please run $ . init_simenv.sh")
endif

test:
	axi.sh 	--top axis_fifo \
		--create-axis-sim-proj \
		--axi-type stream \
		--interface-type master_slave \
		--force
	simulate.sh --sim

clean:
	rm -rf $(IP_REPO_DIR) $(PROJ_DIR) $(SIM_DIR)

.SILENT: clean
.PHONY: clean test
