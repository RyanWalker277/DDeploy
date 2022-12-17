#! /bin/sh

set -x
set -e

green=`tput setaf 2`

# updating the packages
echo "${green}Updating packages....."
sudo -u root apt update -y && sudo -u ubuntu  apt upgrade -y >/dev/null
# installing python-dev , pip and nginx
echo "${green}Installing necessary packages....."
sudo -u root apt install -y python3-pip python3-dev nginx >/dev/null
# installing virtualenv
echo "${green}Installing virtualenv python package...."
sudo -u ubuntu pip3 install virtualenv >/dev/null
# creating virtualenv
echo "${green}Creating virtualenv"
virtualenv env >/dev/null
# activating virtualenv
echo "${green}Activating virtualenv....."
sudo -u ubuntu source env/bin/activate #PROBLEM
# installing gunicorn
echo "${green}Installing gunicorn....."
sudo -u ubuntu pip install django gunicorn >/dev/null
# getting repo link
echo "${green}Provide a link to your github repo"
read repo 
# cloning repo
echo "${green}Cloning Github repo....."
sudo -u ubuntu git clone $repo >/dev/null
# getting project name
echo "${green}What's the name of your Django Project? (Provide the name which you used while running the 'django-admin startproject' command"
read name
# moving into project directory
cd $name 
# installing project directory
sudo -u ubuntu pip3 install -r requirements.txt >/dev/null
# internally opening the port
echo "${green}Allowing traffic internally for port 8000....."
sudo -u root ufw allow 8000 >/dev/null
# installing supervisor
echo "${green}Installing supervisor..."
sudo -u root apt-get install -y supervisor >/dev/null
# checking if directory exists
DIR="/etc/supervisor/conf.d/"
if [ -d "$DIR" ]; then
#   create socket file for gunicorn
  echo "${green}${DIR} found"
  if [ -f "/etc/supervisor/conf.d/gunicorn.conf" ]; 
    then
      echo "${green}Deleting existing gunicorn.conf file"
      sudo -u root rm /etc/supervisor/conf.d/gunicorn.conf >/dev/null
      echo "${green}Creating gunicorn.conf file in ${DIR}..."
      sudo -u root printf "[program:gunicorn]\ndirectory=/home/ubuntu/$workingdir\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $name.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf
    else
      echo "${green}Creating gunicorn.conf file in ${DIR}..."
      sudo -u root printf "[program:gunicorn]\ndirectory=/home/ubuntu/$workingdir\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $name.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf #PROBLEM
  fi
fi
  echo "${green}${DIR} not found"
  echo "${green}creating ${DIR}..."
  sudo -u root mkdir /etc/supervisor/conf.d/ >/dev/null
  echo "${green}created ${DIR}..." 
  echo "${green}What is the name of your repository"
  read workingdir
  echo "${green}Creating gunicorn.conf file in ${DIR}..."
  printf "[program:gunicorn]\ndirectory=/home/ubuntu/$workingdir\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $name.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf 

echo "${green}Making log directory"
sudo -u root mkdir /var/log/gunicorn >/dev/null
echo "${green}Updating supervisor processes"
sudo -u root supervisorctl reread >/dev/null
sudo -u root supervisorctl update >/dev/null

echo "${green}What is the Public IP of your instance?"
read IP

# checking if directory exists
DIR="/etc/nginx/sites-available/"
if [ -d "$DIR" ]; then
#   create conf file for nginx
  echo "${green}${DIR} found"
  if [ -f "/etc/nginx/sites-available/django.conf" ]; 
    then
      echo "${green}Deleting existing django.conf file"
      sudo -u root rm /etc/nginx/sites-available/django.conf >/dev/null
      echo "${green}Creating django.conf file in ${DIR}..."
      sudo -u root printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf
    else
      echo "${green}Creating django.conf file in ${DIR}..."
      sudo -u ubuntu printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf
  fi
fi
  echo "${green}${DIR} not found"
  echo "${green}are you sure NGINX is correctly installed?"
  echo "${green}creating ${DIR}..."
  sudo -u root mkdir /etc/nginx/sites-available/ >/dev/null
  echo "${green}created ${DIR}..." 
  echo "${green}Creating django.conf file in ${DIR}..."
  echo "${green}What is the Public IP of your instance?"
  read IP
  sudo -u ubuntu  printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf
echo "${green}Testing the conf file"
sudo -u root nginx -t >/dev/null
echo "${green}Creating symlink for the conf file"
sudo -u root ln django.conf /etc/nginx/sites-enabled >/dev/null
echo "${green}chaning nginx user for acessing app.sock"
sudo -u root sed -i 's/user www-data;/user ubuntu;/' /etc/nginx/nginx.conf
echo "${green}Restarting Nginx"
sudo -u root service nginx restart >/dev/null

echo "${green}The task is done! Your project is up and running. Just visit $IP to view your deployment"

# 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
