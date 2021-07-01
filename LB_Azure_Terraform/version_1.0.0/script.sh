#!/bin/sh
sudo apt-get update
sudo apt install -y apache2
sudo systemctl status apache2
sudo systemctl start apache2
sudo chown -R $USER:$USER /var/www/html
sudo echo "<html><h1>VM1</h1><br>Build by Terraform!</html>" > /var/www/html/index.html
