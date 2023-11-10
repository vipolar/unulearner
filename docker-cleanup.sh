#!/bin/bash

script_file="./$(basename "${BASH_SOURCE[0]}")"

if [ "$EUID" -eq 0 ]; then
    echo "ABORTING: script was invoked by a super user!"
    echo "HINT: no sudoers allowed!"
    exit
fi

if [ "$0" != "$script_file" ]; then
    echo "ABORTING: script invocation error occurred!"
    echo "HINT: invoke the script as a local executable: ./example.sh"
    exit
fi

sudo docker compose down

echo "Enter 'NUCLEAR' if you want to destroy everything associated with this docker compose:"
read confirmation

if [ "$confirmation" = "NUCLEAR" ]; then
    sudo docker system prune -a -f --volumes #NUCLEAR OPTION!

    sudo rm -rf nginx
    sudo rm -rf pgadmin
    sudo rm -rf postgresdb
else
    echo "Would you like to remove dangling volumes? [y/N]: "

    read confirmation
    confirmation_lower=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [ "$confirmation_lower" = "y" ]; then
        sudo docker volume rm $(sudo docker volume ls -q --filter dangling=true)
    fi

    echo "Would you like to remove all remaining volumes? [y/N]: "

    read confirmation
    confirmation_lower=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [ "$confirmation_lower" = "y" ]; then
        sudo docker volume rm $(docker volume ls -q)
    fi

    echo "Would you like to remove the local directories associated with the docker volumes? [y/N]: "

    read confirmation
    confirmation_lower=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [ "$confirmation_lower" = "y" ]; then
        sudo rm -rf nginx
        sudo rm -rf pgadmin
        sudo rm -rf postgresdb
    fi
fi
