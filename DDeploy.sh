#! /bin/sh
helpFunction()
{
   echo ""
   echo "Usage: $0 -link link-to-repo -name name-of-repo -proj proj-name -ip ip-of-instance"
   echo -e "\t--link Link to your github repo"
   echo -e "\t--name Name of your github repo"
   echo -e "\t--proj Name of your Django Project (one which you used with createproject command"
   echo -e "\t--ip public ip of you instance"
   bash
}

while [ $# -gt 0 ] ; do
  case $1 in
    -l | --link) link="$2" ;;
    -n | --name) name="$2" ;;
    -w | --proj) proj="$2" ;;
    -i | --IP) IP="$2" ;;
  esac
  shift
done

if [ -z "$link" ] || [ -z "$name" ] || [ -z "$proj" ] || [ -z "$IP" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi
sudo -u root apt-get update -y &&   apt-get upgrade -y 
sudo -u root apt-get install -y python3-pip python3-dev nginx python3-virtualenv
pip3 install virtualenv 
virtualenv env 
. env/bin/activate
pip install django gunicorn 
git clone $link 
cd $name
pip3 install -r requirements.txt 
python manage.py makemigrations 
python manage.py migrate 
sudo -u root ufw allow 8000 
sudo -u root apt-get install -y supervisor 

DIR="/etc/supervisor/conf.d/"
if [ -d "$DIR" ]; then
  echo "${green}${DIR} found"
  if [ -f "/etc/supervisor/conf.d/gunicorn.conf" ];
    then
      echo "${green}Deleting existing gunicorn.conf file"
      sudo -u root rm /etc/supervisor/conf.d/gunicorn.conf 
      echo "${green}Creating gunicorn.conf file in 1 ${DIR}..."
      sudo -u root printf "[program:gunicorn]\ndirectory=/home/ubuntu/$name\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $proj.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf >>/dev/null
    else
      echo "${green}Creating gunicorn.conf file in ${DIR}..."
      sudo -u root printf "[program:gunicorn]\ndirectory=/home/ubuntu/$name\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $proj.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf >>/dev/null
  fi
else
  echo "${green}${DIR} not found"
  echo "${green}creating ${DIR}..."
  sudo -u root mkdir -p /etc/supervisor/conf.d/ 
  echo "${green}created ${DIR}..."
  echo "${green}Creating gunicorn.conf file in 1${DIR}..."
  printf "[program:gunicorn]\ndirectory=/home/ubuntu/$name\ncommand=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/app.sock $proj.wsgi:application\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/gunicorn/gunicorn.err.log\nstdout_logfile=/var/log/gunicorn/gunicorn.out.log\n\n[group:guni]\nprogram:gunicorn\n" | sudo tee /etc/supervisor/conf.d/gunicorn.conf >>/dev/null
fi

sudo -u root mkdir /var/log/gunicorn 
sudo -u root supervisorctl reread 
sudo -u root supervisorctl update 
DIR="/etc/nginx/sites-available/"
if [ -d "$DIR" ]; then
  echo "${green}${DIR} found"
  if [ -f "/etc/nginx/sites-available/django.conf" ];
    then
      echo "${green}Deleting existing django.conf file"
      sudo -u root rm /etc/nginx/sites-available/django.conf 
      echo "${green}Creating django.conf file in ${DIR}..."
      sudo -u root printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf >>/dev/null
    else
      echo "${green}Creating django.conf file in ${DIR}..."
      printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf >>/dev/null
  fi
else
  echo "${green}${DIR} not found"
  echo "${green}are you sure NGINX is correctly installed?"
  echo "${green}creating ${DIR}..."
  sudo -u root mkdir -p /etc/nginx/sites-available/ 
  echo "${green}created ${DIR}..."
  echo "${green}Creating django.conf file in ${DIR}..."
  printf "server {\n\tserver_name $IP;\n\tclient_max_body_size 100M;\n\tlocation / {\n\t\tinclude proxy_params;\n\t\tproxy_pass http://unix:/home/ubuntu/app.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/django.conf >>/dev/null
fi
sudo -u root nginx -t 
sudo -u root ln /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled 
sudo -u root sed -i 's/user www-data;/user ubuntu;/' /etc/nginx/nginx.conf
sudo -u root service nginx restart 

echo "${green}The task is done! Your project is up and running. Just visit $IP to view your deployment"
bash