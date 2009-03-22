#!/bin/sh
scan-build xcodebuild -target iPhone -configuration Debug -project iPhone.xcodeproj -sdk iphonesimulator2.2.1
scan-build xcodebuild -target Mac -configuration Debug -project Mac.xcodeproj 
