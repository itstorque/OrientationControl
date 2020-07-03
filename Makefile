TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

SUBPROJECTS += orientationcontrolpreferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OrientationControl

OrientationControl_FILES = Tweak.x toggle.x
OrientationControl_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

include $(THEOS_MAKE_PATH)/aggregate.mk
