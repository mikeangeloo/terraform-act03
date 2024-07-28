provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
}

module "security-groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

module "load-balancer" {
  source            = "./modules/load-balancer"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = [module.vpc.app_subnet_id, module.vpc.db_subnet_id]
  security_group_id = module.security-groups.app_sg_id
}
module "instances" {
  source = "./modules/instances"
  instances = {
    mean-db = {
      ami               = "ami-04a81a99f5ec58529"
      instance_type     = "t2.micro"
      subnet_id         = module.vpc.db_subnet_id
      security_group_id = module.security-groups.db_sg_id
      key_name          = "UNIR-DEVOPS"
      tags              = {}
    }
    mean-app = {
      ami               = "ami-04a81a99f5ec58529"
      instance_type     = "t3a.small"
      subnet_id         = module.vpc.app_subnet_id
      security_group_id = module.security-groups.app_sg_id
      key_name          = "UNIR-DEVOPS"
      tags              = {}
    }
  }
}
# module "db_setup" {
#   source           = "./modules/remote-setup"
#   user             = "ubuntu"
#   private_key      = "${path.module}/UNIR-DEVOPS.pem"
#   host             = module.instances.public_ips["mean-db"]
#   timeout          = "5m"
#   inline_commands  = ["mkdir -p /home/ubuntu/code/scripts"]
#   file_source      = "${path.module}/scripts/mongodb-setup.sh"
#   file_destination = "/home/ubuntu/code/scripts/mongodb-setup.sh"
#   inline_post_commands = [
#     "chmod +x /home/ubuntu/code/scripts/mongodb-setup.sh",
#     "/home/ubuntu/code/scripts/mongodb-setup.sh"
#   ]
#   depends_on = [module.instances.mean_db]
# }

# module "app_setup" {
#   source           = "./modules/remote-setup"
#   user             = "ubuntu"
#   private_key      = "${path.module}/UNIR-DEVOPS.pem"
#   host             = module.instances.public_ips["mean-app"]
#   timeout          = "5m"
#   inline_commands  = ["mkdir -p /home/ubuntu/code/scripts"]
#   file_source      = ""
#   file_content = templatefile("${path.module}/scripts/app-setup.sh.tpl", {
#     db_host = module.instances.private_ips["mean-db"]
#   })
#   file_destination = "/home/ubuntu/code/scripts/app-setup.sh"
#   inline_post_commands = [
#     "chmod +x /home/ubuntu/code/scripts/app-setup.sh",
#     "/home/ubuntu/code/scripts/app-setup.sh"
#   ]
#   depends_on = [module.instances.mean_app, module.db_setup]
# }



resource "null_resource" "db_setup" {
  # Crear el directorio de destino en la máquina remota antes de copiar el archivo
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/code/scripts"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-db"]
      timeout     = "5m"
      agent       = false
    }
  }

  # Copiar el archivo de script a la máquina remota
  provisioner "file" {
    source      = "${path.module}/scripts/mongodb-setup.sh"
    destination = "/home/ubuntu/code/scripts/mongodb-setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-db"]
      timeout     = "5m"
      agent       = false
    }
  }

  # Ejecutar el script remoto
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/code/scripts/mongodb-setup.sh",
      "/home/ubuntu/code/scripts/mongodb-setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-db"]
      timeout     = "5m"
      agent       = false
    }
  }

 depends_on = [module.instances.mean_db]
}
resource "null_resource" "app_setup" {

   provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/code/scripts"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-app"]
      timeout     = "1m"
      agent       = false
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-setup.sh.tpl", {
      db_host = module.instances.private_ips["mean-db"]
    })
    destination = "/home/ubuntu/code/scripts/app-setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-app"]
      timeout     = "4m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/code/scripts/app-setup.sh",
      "/home/ubuntu/code/scripts/app-setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/UNIR-DEVOPS.pem")
      host        = module.instances.public_ips["mean-app"]
      timeout     = "8m"
    }
  }

  depends_on = [module.instances.mean_app, null_resource.db_setup]
}