#!/bin/sh

# If we aren't running from the command line, then exit
if [ "$GHUNIT_CLI" != "1" ]; then
  exit 0
fi

export DYLD_ROOT_PATH="$SDKROOT"
export DYLD_FRAMEWORK_PATH="$CONFIGURATION_BUILD_DIR"

"$TARGET_BUILD_DIR/$EXECUTABLE_PATH" -RegisterForSystemEvents
RETVAL=$?

exit $RETVAL
	


