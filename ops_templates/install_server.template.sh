#!/bin/bashf
set -e

# This is a template for a script that builds a server from bare metal. It is missing
# a lot of details that need to be filled in

# ==============safety checks ==============
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# ============== needed variables ==============
hostname=
username=
service_user_password=
env=

# ==============begin installation ==============
hostnamectl set-hostname $hostname


export ENV=$env  # also happens in gunicorn file

# ============== update ubuntu ==============
apt install -y unattended-upgrades
apt update -y
apt upgrade -y
apt install -y nginx
apt install -y postgresql-client-common
apt install -y postgresql-client
apt install -y libpq-dev python3-dev
apt install -y gcc
apt install -y emacs

adduser $username --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "$username:$service_user_password" | chpasswd
usermod -aG sudo $username
mkdir -p /home/$username/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCctS8JEYZzmmyrfEel6zdnFZ2bAY1Z6g2WT7Jso6KPXDUEGKMhoNFcJR3llcZuoCVnJhhzx9fXkb/FBXwhCAwiBODWuV49InQHzWbSg3irwrjdV95rJPT68hPXxBLx6yxdLIwsdDnThVeTZB1lJpnhjKPy9WuSoDsSL9yFUAdQlbzuaXXo7smR28VlxMJlMjFlRlm2qbmm0omEAf2zC2NJzkd6DffWuLtQXlIaoDc75LTQCILSvVwWNAVIb6OFTlt/6XEUUIhW29OD14PxKcE2XiW73uuvGzvqrqQWoJdtO1hjUN5p8SUGODwqUFO+saxYZySXIArqm4LQ+CBKvY0mWeWPS5C8GFXoESaEZ+ixKiuHlxYtCVE5RWycISDRgVg5nhrTTL2+jYWRRscGyQlPSB9U4qIqC/hoKwMZUKwMIrakdEMs3sgDuBEkX1VBOKuY2KB73PyLsz4DH0Jbk5maDRfR66Q2ZKdsaFrFKcupKC7lBJ1ZIX7/U58b4+5AU9L2rPu17JoyyJ0CsC3YEynzEOg8njgOgg522DPOpViEptYZXhfYBbA6EnOtnXHhouf5kSEg+1ZsQdcClPHMQl0UsIK8gq4gf2jplcwrtSBMr4qSLuBMISd2MLBcoQvYcBO2LKDkfsvSdyqxIV5VUOeS80nef/YGni3ISHykktbLhQ== support@get$username.com" > /home/$username/.ssh/authorized_keys
chown -R $username:$username /home/$username/.ssh/
chmod 664 /home/$username/.ssh/authorized_keys

# ============= ssl certs ======================
vpcip=
if [ ! -f $vpcip.key ]; then
    echo "Missing $vpcip.key file"
    exit 1
fi
if [ ! -f $vpcip.crt ]; then
    echo "Missing $vpcip.crt file"
    exit 1
fi

mv $vpcip.crt /etc/ssl/certs/$username.crt
mv $vpcip.key /etc/ssl/certs/$username.key

# ==========  setup app ==========  #

# this entire section should probably be replaced with a docker container
# deploy
cd /usr/src

# RUN DEPLOY SCRIPT HERE


# ============== logfiles ==============
mkdir /var/log/$servicename
chown -R $username:$username /var/log/$servicename/

# ============== file ownership ==============
chown -R $username:$username /usr/src/venv/$username
chown -R $username:$username /usr/src/covid
chown -R $username:$username /var/log/$username/

# ============== install daemon ==============
servicename=
cat > /etc/systemd/system/$servicename.service << EOM
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=$username
WorkingDirectory=/usr/src/covid
Environment="ENV=$env"
ExecStart=/usr/src/venv/$servicename/bin/gunicorn --log-syslog --workers 4 --bind 0.0.0.0:8000 $servicename.app:app

[Install]
WantedBy=multi-user.target
EOM

systemctl enable /etc/systemd/system/$servicename.service


# TODO: ADD LOG ROTATION HERE

# ======= nginx ==========
rm /etc/nginx/sites-enabled/default
ln -s /usr/src/covid/prod_ops/$username.conf /etc/nginx/sites-enabled/default

# ===== start services =========
service $username start
service nginx restart


# ========== HTTPS via certbot =================
apt -y install software-properties-common
add-apt-repository universe
add-apt-repository ppa:certbot/certbot
apt -y update
apt install -y letsencrypt
apt -y install certbot python-certbot-nginx

echo "Starting certbot ssl cert installation."
echo "You will be required to answer manual prompts."
certbot --nginx

# ======== disallow root user ssh ==============

echo "DenyUsers ubuntu" >> /etc/ssh/sshd_config

# reboot
sudo shutdown -r now
