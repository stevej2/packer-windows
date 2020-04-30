#!/bin/bash
# date +%F_%T
echo "Building windows_10 using VirtualBox builder"
time packer build -force --only=virtualbox-iso windows_10.json
# date +%F_%T