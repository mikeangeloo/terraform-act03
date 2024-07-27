#!/bin/sh
sleep 30

### Paso 1: Instalación de node js
# Instalando node js
cd ~
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs
# Revisando versión de node y npm
node -v
npm -v
# Instalación de build-essential para aquellos que requieren compilar código desde la fuente
sudo apt install -y build-essential
###

### Paso 2: Descargando proyecto y preparación
# Instalando github
sudo apt-get install git-all -y
# Creando carpeta de proyectos y clonando repo
cd ~
mkdir -p projects
cd projects
# Clonando repositorio de github
git clone https://github.com/mikeangeloo/mean-stack-example-act03.git mean-stack-app
# Instalando paquetes del proyecto
cd mean-stack-app
# Haciendo pull a ultimos cambios
git pull
# Instalando paquetes del package.json
npm install
# Configurando variables de entorno para la conexión a MongoDB
sudo rm server/.env
echo "DB_USER=appuser" >> server/.env
echo "DB_PASSWORD=apppassword123" >> server/.env
echo "DB_HOST=18.118.26.20" >> server/.env
echo "DB_NAME=meanStackExample" >> server/.env
# Construyendo app
npm run build
###

### Paso 3: Instalando PM2
sudo npm install pm2@latest -g
###

### Paso 4: Configuración de PM2 para ejecutar backend
# Configurando pm2 para ejecutar backend server en el arranque
cd ~
mkdir -p ~/code/backend
cp -fr ~/projects/mean-stack-app/server/dist/. ~/code/backend
cd  ~/code/backend
sudo pm2 start server.js
sudo pm2 startup systemd
sudo pm2 save
# Iniciando servicio personalizado en pm2
sudo systemctl status pm2-root
sudo pm2 list
###

### Paso 5: Moviendo compilado frontend
sudo cp -fr ~/projects/mean-stack-app/client/dist/. /usr/share/nginx/html
###

### Paso 6: Configurando Nginx como servidor proxy inverso
sudo service apache2 stop
sudo apt install -y nginx
# Comprobando que el servicio Nginx se esté ejecutando
sudo systemctl status nginx
sudo rm /etc/nginx/sites-available/default
#Moviendo la configuración para proxy conf.d
sudo cp -fr ~/projects/mean-stack-app/config/nginx/nginx.conf /etc/nginx/sites-available/default
#Reiniciando el servidor nginx para aplicar cambios
sudo systemctl restart nginx
###