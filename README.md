## Pre-condiciones
- Obtener los secrets de la cuenta de amazon y crear un archivo en raíz con estas variables: terraform.tfvars
Ej.
```
access_key = "TU ACCESS KEY"
secret_key = "TU SECRET KEY"
```
- Tambien necesitarás obtener tu llave privada .pem y colocarla en raíz.

## Estructura de Carpetas

El proyecto está organizado de la siguiente manera:

```
.
├── main.tf
├── outputs.tf
├── variables.tf
├── scripts
│   ├── app-setup.sh.tpl
│   └── mongodb-setup.sh
└── modules
    ├── vpc
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── security-groups
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── instances
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── load-balancer
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```
    
### Para ejecutarlo

#### Inicializa el proyecto
```
terraform init
```

#### Aplica los cambios esperando confirmación
```
terraform apply
```

#### Destruye todo lo definido en la infraestructura
```
terraform destroy
```