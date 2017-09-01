# Fosterbox

A bare-bones minimal but powerful LEMP local dev environment for Vagrant.

## Built with:

* Ubuntu 16.04
* PHP 7
* MySQL 5.7
* NGINX

## Includes:

* Base and common useful PHP modules
* PHP-Unit
* Composer
* Beanstalkd
* WP-CLI
* NGROK
* Memcached
* MailHog

## Building the box:

#### 1. Run the Vagrant machine.

```zsh
vagrant up
```

This process will take as long as it needs to setup the entire box configuration.

#### 2. Package it up.

After it's done, SSH into the box and make sure things are working. Once you properly do QA, you're ready to package the box.

To package the box, we're going to run a few commands.

```zsh
# SSH into the box
vagrant ssh
# "Zero it out" (make it small as possible)
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY
# Clear APT cache (make it smaller)
sudo apt-get autoremove
sudo apt-get clean
# Delete bash history and exit
cat /dev/null > ~/.bash_history && history -c && exit
# Stop the box
vagrant halt
# Package the box with Vagrant
vagrant package --output fosterbox.box
# Add the box to your vagrant!
vagrant box add fosterbox fosterbox.box
```
