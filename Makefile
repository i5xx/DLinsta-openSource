THEOS_DEVICE_IP = localhost
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DLInsta

DLInsta_FILES = Tweak.xm DLManager.m DLGetSafe.m MBProgressHUD.m
DLInsta_CFLAGS = -fobjc-arc -Iinclude

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Instagram" || true