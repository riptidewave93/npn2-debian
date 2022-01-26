#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 01_pre_docker.sh"

# Make sure our BuildEnv dir exists
if [ -d ${build_path} ]; then
    error_msg "BuildEnv already exists, this isn't a clean build! Things might fail, but we're going to try!"
else
    mkdir ${build_path}
fi

# Always build to pickup changes/updates/improvements
debug_msg "Building npn2-debian:builder"
docker build -t npn2-debian:builder ${root_path}

debug_msg "Finished 01_pre_docker.sh"