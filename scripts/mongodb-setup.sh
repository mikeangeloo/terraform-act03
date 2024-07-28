#!/bin/bash
sleep 30

### Paso 1: Actualizar e instalar MongoDB
# Guía tomada de: https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu
sudo apt-get update -y
#Importando llave public GPG de mongodb
sudo apt-get install gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

# Creando el listado de archivos para MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Recargando el paquete local de base de datos
sudo apt-get update -y
# Instalando paquetes de MongoDB
sudo apt-get install -y mongodb-org

# Iniciando servicios de mongdd
sudo systemctl start mongod
sudo systemctl enable mongod
###

### Paso 2: Creando usuario administrativo y habilitando autenticación
#Guía: https://www.mongodb.com/docs/manual/tutorial/configure-scram-client-authentication
mongosh <<EOF
use admin
db.createUser({
  user: "admin",
  pwd: "password123",
  roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
      { role: "readWriteAnyDatabase", db: "admin" }
  ]
})
EOF

# Habilitar autenticación en mongod.conf
#sudo sed -i '/#security:/a\\security:\n  authorization: "enabled"' /etc/mongod.conf

# Verificar si la configuración de authorization ya está presente
grep -q 'authorization: "enabled"' /etc/mongod.conf

# Si el grep anterior falla, significa que la configuración no está presente y la agregamos
if [ $? -ne 0 ]; then
  sudo sed -i '/#security:/a\\security:\n  authorization: "enabled"' /etc/mongod.conf
  echo "Authorization enabled configuration added."
else
  echo "Authorization enabled configuration already present."
fi

# Indicamos que queremos recibir conexiónes abiertas a mongo
sudo sed -i 's/^  bindIp: .*/  bindIp: 0.0.0.0/' /etc/mongod.conf

# Reiniciar MongoDB para aplicar cambios
sudo systemctl restart mongod
###

### Paso 3: Creando usuario para la base de datos de la aplicación
mongosh -u "admin" -p "password123" --authenticationDatabase "admin" <<EOF
use meanStackExample
db.createUser({
  user: "appuser",
  pwd: "apppassword123",
  roles: [{ role: "readWrite", db: "meanStackExample" }]
})
EOF
