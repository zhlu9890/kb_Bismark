SERVICE = kb_bismark
SERVICE_CAPS = kb_Bismark
SPEC_FILE = kb_Bismark.spec
URL = https://kbase.us/services/kb_bismark
DIR = $(shell pwd)
LIB_DIR = lib
SCRIPTS_DIR = scripts
TEST_DIR = test
LBIN_DIR = bin
EXECUTABLE_SCRIPT_NAME = run_$(SERVICE_CAPS)_async_job.sh
STARTUP_SCRIPT_NAME = start_server.sh
TEST_SCRIPT_NAME = run_tests.sh

.PHONY: test

default: compile

all: compile build build-startup-script build-executable-script build-test-script

compile:
	kb-sdk compile $(SPEC_FILE) \
		--out $(LIB_DIR) \
		--plclname $(SERVICE_CAPS)::$(SERVICE_CAPS)Client \
		--jsclname javascript/Client \
		--pyclname $(SERVICE_CAPS).$(SERVICE_CAPS)Client \
		--javasrc src \
		--java \
		--plsrvname $(SERVICE_CAPS)::$(SERVICE_CAPS)Server \
		--plimplname $(SERVICE_CAPS)::$(SERVICE_CAPS)Impl \
		--plpsginame $(SERVICE_CAPS).psgi;

build:
	chmod +x $(SCRIPTS_DIR)/entrypoint.sh

build-executable-script:
	mkdir -p $(LBIN_DIR)
	echo '#!/bin/bash' > $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'perl $$script_dir/../$(LIB_DIR)/$(SERVICE_CAPS)/$(SERVICE_CAPS)Server.pm $$1 $$2 $$3' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	chmod +x $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)

build-startup-script:
	mkdir -p $(LBIN_DIR)
	echo '#!/bin/bash' > $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'export KB_DEPLOYMENT_CONFIG=$$script_dir/../deploy.cfg' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'plackup $$script_dir/../$(LIB_DIR)/$(SERVICE_CAPS).psgi' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	chmod +x $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)

build-test-script:
	echo '#!/bin/bash' > $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export KB_DEPLOYMENT_CONFIG=$$script_dir/../deploy.cfg' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export KB_AUTH_TOKEN=`cat /kb/module/work/token`' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'cd $$script_dir/../$(TEST_DIR)' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo "perl -e 'opendir my \$$dh, \".\"; my @l = grep { /\\\\.pl\$$/ } readdir \$$dh; my \$$ret=0; foreach my \$$s (@l) { print(\"Running \".\$$s.\"\\\\n\"); system(\"perl\", \$$s) && do{\$$ret=2; next;}; } exit(\$$ret);'" >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	chmod +x $(TEST_DIR)/$(TEST_SCRIPT_NAME)

test:
	if [ ! -f /kb/module/work/token ]; then echo -e '\nOutside a docker container please run "kb-sdk test" rather than "make test"\n' && exit 1; fi
	bash $(TEST_DIR)/$(TEST_SCRIPT_NAME)

clean:
	rm -rfv $(LBIN_DIR)
