terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider digitalocean {
    token = var.do_token
}

data "digitalocean_account" "account_info" {

}

output "droplet_limit" {
  value = data.digitalocean_account.account_info.droplet_limit
}

data "digitalocean_ssh_key" "mykey" {
    name = "Silva"
}

resource "digitalocean_droplet" "cookapp-iac" {
    image = "ubuntu-20-04-x64"
    name = "cookapp-iac"
    region = "sfo2"
    size = "s-1vcpu-1gb"
    ssh_keys = [data.digitalocean_ssh_key.mykey.id]

    lifecycle {
      create_before_destroy = true
    }
    connection {
      host = self.ipv4_address
      user = "root"
      type = "ssh"
      private_key = file(var.pvt_key)
      timeout = "2m"
    }
    provisioner "remote-exec" {
      inline = [ 
        "export PATH=$PATH:/usr/bin",
        #install NGINX
        "sudo apt update",
        "sudo apt install -y nginx",
        "sudo systemctl start nginx",
        "echo 'server {listen 80;listen [::]:80;server_name 165.227.240.90;root /var/www/cookapp;index index.html;location / {try_files $uri $uri/ /index.html index.html;}location /api {proxy_pass http://localhost:3000; proxy_set_header Host $host;proxy_set_header X-Real-IP $remote_addr;}}' > /etc/nginx/sites-available/cookapp",
        "ln -s /etc/nginx/sites-available/cookapp /etc/nginx/sites-enabled/",
        "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh",
        "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash",
        "source ~/.bashrc",
        "nvm install lts/iron",
        "sudo apt install -y nodejs",
        "sudo apt install -y npm",
        "git clone https://github.com/hsilv/Proyecto-Software.git",
        "cd Proyecto-Software/",
        "cd Frontend/",
        "npm i",
        "npm run build",
        "mkdir /var/www/cookapp",
        "cd dist/",
        "rsync -av --quiet * /var/www/cookapp/",
        "sudo systemctl start nginx",
       ]
    }
}

output "server_ip" {
  value = digitalocean_droplet.cookapp-iac.ipv4_address
}