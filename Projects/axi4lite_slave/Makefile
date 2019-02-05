REPO_DIR = "ip_repo"

ifndef VIVADO_SDK
$(error "VIVADO_SDK is not set. Please run $ . init_simenv.sh")
endif

ip:
	axi.sh 	--top blinky_top \
		--force \
		--axi-type lite \
		--interface-type slave

clean:
	rm -rf $(REPO_DIR)

.PHONY: clean
.SILENT: clean
