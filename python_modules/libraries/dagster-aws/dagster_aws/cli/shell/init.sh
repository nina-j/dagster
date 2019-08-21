#!/bin/bash

INSTALL_PATH="/opt/dagster"

# For updating nodejs
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

# For updating yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install base deps
apt-get update && apt-get install -y git make python3 python3-pip python-virtualenv nodejs yarn

# Create and chown install path
mkdir -p $INSTALL_PATH
chown -R ubuntu:ubuntu $INSTALL_PATH

# Set up a virtualenv for us to use
sudo -u ubuntu virtualenv --python=/usr/bin/python3 $INSTALL_PATH/venv
source $INSTALL_PATH/venv/bin/activate

pip install -U pip

# clone as user ubuntu
sudo -u ubuntu git clone https://github.com/dagster-io/dagster.git $INSTALL_PATH/dagster

pushd $INSTALL_PATH/dagster
sudo -u ubuntu make dev_install

# user code will go here
mkdir -p $INSTALL_PATH/app
chown -R ubuntu:ubuntu $INSTALL_PATH/app

# Install systemd service
cat <<EOT > /lib/systemd/system/dagit.service
[Unit]
Description=Run Dagit
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/bin/bash -c 'export PYTHONPATH=$PYTHONPATH:/opt/dagster/app && export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && source /opt/dagster/venv/bin/activate && /opt/dagster/venv/bin/dagit --no-watch -h 0.0.0.0 -p 3000 -y /opt/dagster/app/repository.yaml'
Restart=always

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable dagit
