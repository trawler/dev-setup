#cloud-config

runcmd:
- sudo echo '/dev/xvdf /home ext4  defaults,errors=remount-ro 0 1' >> /etc/fstab
- sudo mount -a
- wget -qO - terraform.gpg https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/terraform-archive-keyring.gpg
- echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/terraform-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/terraform.list
- sudo apt update
- sudo apt install -y terraform
- sudo add-apt-repository -y ppa:longsleep/golang-backports && sudo apt update
- sudo apt install -y golang-go zsh
- sudo apt install -y make
# - curl -fsSL https://get.docker.com -o get-docker.sh
# - sudo sh get-docker.sh
# - sudo usermod -aG docker $USER
- sudo snap install kubectl --classic
- sudo snap install helm --classic
- sudo chsh -s $(which zsh) ubuntu

output : { all : '| tee -a /var/log/cloud-init-output.log' }