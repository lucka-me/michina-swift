#!/bin/zsh

set -e

sourceDirectory=$(realpath $(dirname $0))

# Trust the SwiftProtobuf plugin
swiftPMSecurityPath=~/Library/org.swift.swiftpm/security
mkdir -p $swiftPMSecurityPath
cp $sourceDirectory/Security/plugins.json $swiftPMSecurityPath
