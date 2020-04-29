#!/bin/bash
packer build -force --only=virtualbox-iso windows_10.json
