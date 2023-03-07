#!/bin/bash

echo "This app will install and configure flask, Gunicorn, Nginx and the Python virtual environment."
echo "This is not meant for production. You will want security experts to help configure those environments."
echo "The idea is to help you get a more complete testing and development environment and to build experience."
echo "I admit, I am no expert, just someone who enjoys sharing technical knowledge."
echo "I would love feedback and suggestions on how to make this better for everyone."
echo "\n"
echo "Copy this script to a newly installed ubuntu server. My testing was on 22.04."
echo "Do a chmod 775 on the file name and then run it."
echo "Only run this script on a server you wouldn't mind rebuilding or losing data on."


# ################################## #
# Change This Section before running #
# ################################## #

# This is the directory you have wan your flask app installed. I recommend your home
# with the name of your app.
WorkingDirectory="/home/mike/myapp"

# The last directory should match your application and "AppName" in the next line.
# Make sure to match the last section of the working directory above. Like "myapp".
AppName="myapp" 

# This should be your dns name like "test.com" or your IP for testing like "10.0.0.167"
# Make sure it matches the ip of your server.
ServerName="10.0.0.167"
 
# This should be port 80 unless you want it on another port.
ServerPort="80"
 
# This should be 0.0.0.0 unless you have a specific IP bound you want the host on.
ServerIP="0.0.0.0"

# ################## #
# Script starts here #
# ################## #

# Update libs
sudo apt-get update
sudo apt-get -y upgrade 

# This file installs files for python, Gunicorn, and Nginx for ubuntu
sudo apt-get -y install python3 python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
sudo apt -y autoremove  # Removes unneeded files.
 
# Install the python virtual environment
sudo apt-get -y install python3-venv
 
# Install Nginx web server
sudo apt-get -y install nginx
 
# Start and enable the nginx service
sudo systemctl start nginx
sudo systemctl enable nginx
 
# Create the app directory
mkdir $WorkingDirectory
cd $WorkingDirectory

# Install the python virtual environment. 
python3 -m venv venv
 
# Enter virtual environment.
# Use this same command from the app directory to pip install modules,
# or your requirements file.
source venv/bin/activate
 
# Install Gunicorn and flask
pip install wheel
pip install gunicorn flask
 
# Create basic python flask app
printf "from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return 'Welcome to Flask Application named $AppName!'
if __name__ == '__main__':
    app.run(host='127.0.0.1')" >> $AppName.py

# Create WSGI link to Gunicorn
printf "from $AppName import app
if __name__ == '__main__':
    app.run()" >> wsgi.py

# Make error log directory
sudo mkdir /var/log/gunicorn/

# Make Systemd service for flask
sudo bash -c "printf \"[Unit]
Description=Gunicorn instance to serve Flask
After=network.target
[Service]
User=root
Group=www-data
WorkingDirectory=$WorkingDirectory
Environment=\"PATH=$WorkingDirectory/venv/bin\"
ExecStart=$WorkingDirectory/venv/bin/gunicorn --bind 127.0.0.1:5000 wsgi:app --error-logfile /var/log/gunicorn/access.log --capture-output --log-level info
[Install]
WantedBy=multi-user.target\" >> /etc/systemd/system/flask.service"
 
# After you update your script you will want to set proper permissions. This is one possible example.
#sudo chown -R root:www-data $WorkingDirectory
#sudo chmod -R 775 $WorkingDirectory
 
# Remove default site from Nginx. If we don't Nginx will serve up this default site. 
sudo rm -fR /etc/nginx/sites-enabled/default

# Reloading the systemd daemon
sudo systemctl daemon-reload
 
# Start the flask services, then enable it on reboot
sudo systemctl start flask
sudo systemctl enable flask
 
# Make Nginx revers proxy flask for port 80
sudo rm /etc/nginx/conf.d/flask.conf 
sudo bash -c "printf \"server {
    listen $ServerPort;
    server_name $ServerName;
    location / {
        include proxy_params;
        proxy_pass  http://0.0.0.0:5000;
    }
}\" >> /etc/nginx/conf.d/flask.conf"
 
# Check config file for Nginx
sudo nginx -t
 
# Finally, restart Nginx
sudo systemctl stop flask.service
sudo systemctl daemon-reload
sudo systemctl start flask.service
sudo systemctl restart nginx
 
echo "\nInstall Complete!"
echo "Test out your flask app in your browser"
echo "If there are problems try: sudo systemctl status flask.service"
echo "Or check the logs under /var/logs/gunicorn/"
echo "Good luck and enjoy"

 

 
