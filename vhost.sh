#!/bin/bash

# exit if command with a nonzero exit value
# e.g.: if git fails
set -e

## Global Variables
#################################################
# Adjust to match your server's configuration
htdocs="/srv/www/vhosts/"
nginxAvailable="/etc/nginx/sites-available/"
nginxEnabled="/etc/nginx/sites-enabled/"
hostsFile="/etc/hosts"


## Functions
#################################################
createDirectory()
{
    if [ ! -e $1 ]; then
        mkdir -p "$1"
        writeMessage "... Directory '$1' was created"
    else
        writeMessage "... Directory '$1' exists"
    fi
}

remove()
{
    if [ $1 != "" -a $1 != "." ]; then

        if [ -e $1 ]; then
            rm -r "$1"
        fi

        writeMessage "... '$1' was removed"
    else
        writeMessage '... Access denied'
    fi
}

writeMessage()
{

    printf "$1\n"
}

getConfig()
{
    echo -ne "server { \\r
        listen 80; \\r
        server_name $1; \\r
        root $htdocs$1/public/; \\r
        \\r
        error_log $htdocs$1/log/$1_errors.log; \\r
        access_log $htdocs$1/log/$1_access.log; \\r
    }"
}

isRunning()
{
    if ps ax | grep -v grep | grep $1 > /dev/null
    then
        echo "1"
    else
        echo "0"
    fi
}

cloneRepository()
{
    writeMessage "\n# Cloning repository"
    git clone $1 $2
    writeMessage '... Repository has been cloned'
}

findHostname()
{
    if [ ! -z "$1" ]; then
        hostName=$1
    else
        while [ -z "$hostName" ]; do
            read -p "Enter virtual host name: " hostName
        done
    fi
}

findRepository()
{
    if [ ! -z "$1" ]; then
        repositoryAddress=$1
    else
        while [ -z "$repositoryAddress" ]; do
            read -p "Enter repository address: " repositoryAddress
        done
    fi
}

runNginx()
{
    if [ $(isRunning "nginx") = "1" ]; then
        writeMessage "\n# Reloading nginx configuration"
        nginx -s reload
    else
        writeMessage "\n# Starting nginx"
        nginx
    fi
}

addHost()
{
    if [ ! -d "$htdocs/$hostName/log" ]; then
        writeMessage "\n# Adding log directory"
        createDirectory "$htdocs$hostName/log"
    fi
    if [ ! -d "$htdocs$hostName/public" ]; then
        writeMessage "\n# Adding public directory"
        createDirectory "$htdocs$hostName/public"
    fi

    writeMessage "\n# Writing config to $nginxAvailable$hostName"
    echo $(getConfig $hostName) > "$nginxAvailable$hostName"

    writeMessage "\n# Enabling $hostName in nginx"
    ln -s $nginxAvailable$hostName $nginxEnabled$hostName

    writeMessage "\n# Adding $hostName into $hostsFile"
    echo "127.0.0.1 $hostName" >> $hostsFile
}

removeHost()
{
    writeMessage "\n# Removing files"
    remove "$htdocs$hostName"

    writeMessage "\n# Disabling configuration"
    if [ -h "$nginxEnabled$hostName" ]; then
        rm "$nginxEnabled$hostName"
        writeMessage "... Removed $nginxEnabled$hostName"
    fi

    writeMessage "\n# Removing configuration"
    if [ -e "$nginxAvailable$hostName" ]; then
        rm "$nginxAvailable$hostName"
        writeMessage "... Removed $nginxAvailable$hostName"
    fi

    writeMessage "\n# Removing hosts file entry"
    string="127.0.0.1 $hostName"
    sed "/$string/d" $hostsFile > 'hosts.temp'
    mv "hosts.temp" $hostsFile
}

## Logic
#################################################

# check if user is root
if [ $EUID -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# check arguments
while :
do
    case "$1" in

        -a | --add)
            # check for host name
            findHostname "$2"

            # add host
            addHost

            # run nginx
            runNginx

            # quit
            writeMessage "\n# Your new virtual host has been installed. \nFind your configuration file in: $nginxAvailable$hostName\nFind your virtual host directory in: $htdocs$hostName \nBye"
            exit
            ;;

        -c | --clone)
            # check for host name
            findHostname "$2"

            # check for repository address
            findRepository "$3"

            # clone repository
            cloneRepository "$repositoryAddress" "$htdocs$hostName"

            # add host
            addHost

            # run nginx
            runNginx

            # quit
            writeMessage "\n# Your new virtual host has been installed. \nFind your configuration file in: $nginxAvailable$hostName\nFind your virtual host directory in: $htdocs$hostName \nBye"
            exit
            ;;

        -h | --help)
            writeMessage "vhost [ -a | --add ]    [virtual-host-name.tld]\n      [ -r | --remove ] [virtual-host-name.tld]\n      [ -c | --clone ]  [virtual-host-name.tld] [https://github.com/user/repo.git]"
            exit
            ;;

        -r | --remove)
            # check for host name
            findHostname "$2"

            # remove host
            removeHost

            # quit
            writeMessage "\n# The virtual host $hostName has been removed. \nBye!"
            exit
            ;;

        --) # End of all options
            shift
            break
            ;;

        -*) # wut?
            echo "Error: Unknown option: $1" >&2
            writeMessage "Please specify an argument:"
            writeMessage "vhost [ -a | --add ]    [virtual-host-name.tld]\n      [ -r | --remove ] [virtual-host-name.tld]\n      [ -c | --clone ]  [virtual-host-name.tld] [https://github.com/user/repo.git]"
            exit
            ;;

        *)  # No more options
            writeMessage "Please specify an argument:"
            writeMessage "vhost [ -a | --add ]    [virtual-host-name.tld]\n      [ -r | --remove ] [virtual-host-name.tld]\n      [ -c | --clone ]  [virtual-host-name.tld] [https://github.com/user/repo.git]"
            exit
            ;;
    esac
done

# End of file