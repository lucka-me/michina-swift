#!/bin/zsh

set -e

repositoryPath=$(realpath $(dirname $0)/..)

# Trust the SwiftProtobuf plugin
swiftPMSecurityPath=~/Library/org.swift.swiftpm/security
mkdir -p $swiftPMSecurityPath
cp $repositoryPath/ci_scripts/Security/plugins.json $swiftPMSecurityPath
