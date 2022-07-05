#cloud-config

runcmd:
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