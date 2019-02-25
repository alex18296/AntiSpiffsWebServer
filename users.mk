ifeq ($(OS), Windows_NT)
ARDUINO := D:\arduino-1.8.8\arduino_debug.exe
OBJ_DIR := D:\tmp\arduino
else
ARDUINO := /opt/arduino/arduino
OBJ_DIR := /tmp/arduino
endif

VERBOSE_BUILD := --verbose-build
VERBOSE_UPLOAD := --verbose-upload

PORT := /dev/ttyUSB0

ifeq ($(TARGET_BOARD), nodemcuv2)
# NodeMCU 1.0
BOARD := esp8266:esp8266:nodemcuv2:xtal=80,vt=flash,exception=disabled,eesz=4M,ip=lm2f,dbg=Disabled,lvl=None____,wipe=none,baud=115200
else ifeq ($(TARGET_BOARD), esp32-devmodule)
# ESP32 Dev Module
BOARD := esp32:esp32:esp32:PSRAM=disabled,PartitionScheme=default,CPUFreq=240,FlashMode=qio,FlashFreq=80,FlashSize=4M,UploadSpeed=921600,DebugLevel=none
else ifeq ($(TARGET_BOARD), nodemcu-32s)
# NodeMCU-32S
BOARD := esp32:esp32:nodemcu-32s:FlashFreq=80,UploadSpeed=921600
endif
