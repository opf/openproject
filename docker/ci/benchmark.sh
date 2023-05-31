#!/bin/bash -ex
# This script can be used to quickly launch a full test run on any ubuntu-based VM
#
#     cat benchmark.sh | ssh root@VM bash -s BRANCH -ex -

BRANCH="${1:=dev}"

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y git docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

useradd -m -d /home/dev -s /bin/bash -G docker dev
su - dev -c "git clone https://github.com/opf/openproject --depth=1 --branch=$BRANCH"
su - dev -c 'cd openproject && time docker compose -f docker-compose.ci.yml run --build ci setup-tests run-units run-features'