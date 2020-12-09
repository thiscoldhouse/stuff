#!/bin/bash
# this is a generic deploy script through ssh. It requires filling in details and can't be
# run as is

set -e

envpath=$1  # local path to secrets
sshuser=$2
sshpath=$3  # local path to ssh key
reponame=$4 # cloneable repo path, probably https
prodpath=$5

localdeploy= # where the repo should be cloned locally for ssh
deploysecretspath= # where in the above path the secrets should live
servers= # space seperated list of IPs or hostnames

read -p "Is your $envpath up to date?? y/N" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

cd /tmp
git clone $reponame
cp $envpath $deploysecretspath

# get hash for commit we're deploying
cd $localdeploy
thiscommit=$(git rev-parse HEAD)
deploytime=$(date +%s)
deployname="$thiscommit-$deploytime"
cd /tmp
tar -czvf /tmp/$deployname.tar.gz $localdeploy  # tar created
rm -rf $localdeploy

# send the new artifact to the servers
echo "Beaming tar'd code to the servers"

for host in servers
do
    echo "Working on $host"
    scp -i $sshpath /tmp/$deployname.tar.gz $sshuser@$host:/tmp/
    ssh -t  -i $sshpath $sshuser@$host
    echo "$host done"
done

for host in servers
do
    echo "Deploying newly tared code"
ssh -t  -i $sshpath brio@app-arsenic "
                   sudo /bin/rm -rf $prodpath &&
                   sudo /bin/ln -s /usr/src/deploys/$deployname $prodpath &&
                   cd $prodpath &&
                   MIGRATIONS AND REQUIREMENTS GO HERE"
echo "Done"
done

echo "All deploys done"

# clean up
rm $localdeploy
