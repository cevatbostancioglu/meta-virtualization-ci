#!/usr/bin/env bash

set -o errexit  # stop on first error
set -o xtrace  # log every step
set -o nounset  # exit when script tries to use undeclared variables

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit 1
fi

#### CONFIG
GITLAB_URL="http://localhost"
GITLABRUNNER_USER="<pipeline_user>"

if [ "$GITLABRUNNER_USER" = "<pipeline_user>" ]; then
  echo "Please change <pipeline_user> with your pipeline user."
  echo "This scripts requires to add that pipeline user into sudoers file, change gitlab-runner user to pipeline user."
  exit 1
fi

####

##### INSTALL GITLAB-EE
apt-get update
apt-get install -y curl openssh-server ca-certificates
apt-get install -y postfix

curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

EXTERNAL_URL="${GITLAB_URL}" apt-get install -y gitlab-ee

#### INSTALL GITLAB-RUNNER
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
apt-get update
apt-get install -y gitlab-runner

systemctl stop gitlab-runner
cp gitlab-runner.service /etc/systemd/system/
sed -i "s|\"--user\" \"gitlab-runner\"|\"--user\" \"${GITLABRUNNER_USER}\"|g" /etc/systemd/system/gitlab-runner.service
systemctl restart gitlab-runner

### TAKE SUDO RIGHTS
echo "${GITLABRUNNER_USER}  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

### MAIN BUILD DIRECTORY. It's hard to check all user rights from build.sh
mkdir -p /build || true
chown -R ${GITLABRUNNER_USER}:${GITLABRUNNER_USER} /build

### INSTALL YOCTO BASIC HOST TOOLS
### https://www.yoctoproject.org/docs/latest/brief-yoctoprojectqs/brief-yoctoprojectqs.html
### Build Host Packages
apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
     pylint3 xterm

### install dnf
apt-get install -y yum

### INSTALL BATS
git clone https://github.com/sstephenson/bats.git
cd bats
./install.sh /usr/local

### DOCS build
# spelling
apt-get install -y nodejs node.js 
apt-get install -y npm
npm install -g markdown-spellcheck --ignore-scripts
npm install -g remarkable --ignore-scripts
ln -s /usr/bin/nodejs /usr/bin/node
# pdf
apt-get install -y pandoc texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra


exit 0
