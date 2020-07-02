TARGET := iphone:clang:11.2:7.0
# TODO: Upgrade SDK for Preference.framework support

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = OrientationControlPreferences

OrientationControlPreferences_FILES = OrientationControlRootListController.m
OrientationControlPreferences_FRAMEWORKS = UIKit
OrientationControlPreferences_PRIVATE_FRAMEWORKS = Preferences
OrientationControlPreferences_INSTALL_PATH = /Library/PreferenceBundles
OrientationControlPreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
