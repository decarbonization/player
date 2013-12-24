#!/bin/bash
#
#	prep
#	
#	Created by Peter MacWhinnie on 2011-2-12.
#	Copyright Roundabout 2011. All Rights Reserved.
#

APP_PATH=$1
if [ "$APP_PATH" = "" ]; then
	echo "usage: $0 <path to app>"
	exit
fi

# Tasks:
remove_framework_headers() {
	echo "Removing Framework Headers..."
	
	# From <http://www.cimgf.com/2008/09/04/cocoa-tutorial-creating-your-very-own-framework/>
	cd $APP_PATH/Contents/Frameworks 
	rm -rf */Headers 
	rm -rf */Versions/*/Headers 
	rm -rf */Versions/*/PrivateHeaders 
	rm -rf */Versions/*/Resources/*/Contents/Headers
}

update_version() {
	VERSION=$(date +"%Y.%m.%d")
	echo "Updating Version to $VERSION..."
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" $APP_PATH/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" $APP_PATH/Contents/Info.plist
}

reveal_in_finder() {
	echo "Revealing..."
	open --reveal $APP_PATH
}

timebomb_maybe() {
	echo "Should you have removed the timebomb?"
}

remove_framework_headers
update_version
reveal_in_finder
timebomb_maybe
#!/bin/bash
#
#	prep
#	
#	Created by Peter MacWhinnie on 2011-2-12.
#	Copyright Roundabout 2011. All Rights Reserved.
#

APP_PATH=$1
if [ "$APP_PATH" = "" ]; then
	echo "usage: $0 <path to app>"
	exit
fi

# Tasks:
remove_framework_headers() {
	echo "Removing Framework Headers..."
	
	# From <http://www.cimgf.com/2008/09/04/cocoa-tutorial-creating-your-very-own-framework/>
	cd $APP_PATH/Contents/Frameworks 
	rm -rf */Headers 
	rm -rf */Versions/*/Headers 
	rm -rf */Versions/*/PrivateHeaders 
	rm -rf */Versions/*/Resources/*/Contents/Headers
}

update_version() {
	VERSION=$(date +"%Y.%m.%d")
	echo "Updating Version to $VERSION..."
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" $APP_PATH/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" $APP_PATH/Contents/Info.plist
}

reveal_in_finder() {
	echo "Revealing..."
	open --reveal $APP_PATH
}

timebomb_maybe() {
	echo "Should you have removed the timebomb?"
}

remove_framework_headers
update_version
reveal_in_finder
timebomb_maybe