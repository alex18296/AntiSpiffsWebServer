ifneq ($(wildcard users.mk),)
include users.mk
endif

ifeq ($(ARDUINO),)
$(error ARDUINO is not defined)
endif

ifeq ($(BOARD),)
$(error BOARD is not defined)
endif

PROJECT := AntiSpiffsWebServer
OBJ_DIR := $(OBJ_DIR)_$(PROJECT)

all: $(OBJ_DIR)
	$(ARDUINO) $(VERBOSE_BUILD) --verify --pref build.path=$(OBJ_DIR) --board $(BOARD) $(PROJECT).ino

clean:
	rm -rf $(OBJ_DIR)

upload: $(OBJ_DIR)
ifeq ($(PORT),)
	$(error PORT is not defined)
else
	$(ARDUINO) $(VERBOSE_BUILD) $(VERBOSE_UPLOAD) --upload --port $(PORT) --pref build.path=$(OBJ_DIR) --board $(BOARD) $(PROJECT).ino
endif

$(OBJ_DIR):
	mkdir -p $@
