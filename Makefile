
default:
	# Set default make action here
	xcodebuild -target "${TARGETNAME} (Device)" -configuration ${BUILD_STYLE} -project ${PROJECT_NAME}.xcodeproj
	xcodebuild -target "${TARGETNAME} (Simulator)" -configuration ${BUILD_STYLE} -project  ${PROJECT_NAME}.xcodeproj
	sh iOSFramework.sh

# If you need to clean a specific target/configuration: $(COMMAND) -target $(TARGET) -configuration DebugOrRelease -sdk $(SDK) clean
clean:
	-rm -rf build/*

test:
	#change the target to whatever needs to be tested
	GHUNIT_CLI=1 xcodebuild -target Tests -configuration ${BUILD_STYLE} build
