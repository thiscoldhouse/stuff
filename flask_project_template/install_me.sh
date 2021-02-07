echo "Create a folder ~/venv"
read -p "Did you make it? y/N "
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

read -p "Install virtualenv on your machine."
read -p "Did you do that? y/N "
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

virtualenv --python $(which python3) ~/venv/flaskproject
source ~/venv/flaskproject/bin/activate

echo "Installing python requirements"
pip install -r $PWD/requirements.txt

echo "You can now run code locally in a mirror python environment to the docker container"
echo "Happy coding!"
