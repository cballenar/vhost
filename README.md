# Virtual Host Manager for Nginx

Simple manager for creating and removing virtual hosts in nginx powered servers.

## How to

### Download repository 
Download or upload the repository to your server.

e.g. `git clone https://github.com/jsifalda/nginx-server-manager-bash.git`

### Make server manager global! 
Move script to your preferred location for scripts.

e.g.: `/usr/local/bin/vhost`

Don't forget to update your permissions.

e.g.: `chmod +x /usr/local/bin/vhost`

### Set globals
Adjust the global variables to fit your server configuration. The defaults are:
````
htdocs="/srv/www/vhosts/"
nginxAvailable="/etc/nginx/sites-available/"
nginxEnabled="/etc/nginx/sites-enabled/"
hostsFile="/etc/hosts"
````

## Usage

At the moment `sudo` is required when running the script.

### Adding a new host

````
vhost -a my-virtual-host.com
`````

### Creating new host from cloned repository

`````
vhost -c my-virtual-host.com https://github.com/user/repo.git
`````

### Removing host

`````
vhost -r my-virtual-host.com
`````

## Credits
This script is based on [jsifalda's nginx-server-manager-bash](https://github.com/jsifalda/nginx-server-manager-bash) and its forks.

## Todo
- Add option to enabled and disable virtual hosts without removing them, i.e.: removing soft link in `/etc/nginx/sites-enabled/`
- Use sudo only where required. If the www folder is setup with the permissions user:www-data, then root is not required for the creation of these files and it'd be better to have their ownership NOT be root:www-data
- Improving nginx configuration file
- Add some color to the output messages
- What's better `echo` or `printf`?
- Clean up