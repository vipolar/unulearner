#!/bin/bash

script_file="./$(basename "${BASH_SOURCE[0]}")"
unulearner_frontend_path="./unulearner-frontend"

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

if [ -f .env ]; then
    # Load variables from .env file excluding comments
    while IFS= read -r line; do
        if [[ "$line" =~ ^[^#]*= ]]; then
            export "$line"
        fi
    done < .env

    # Export variables with self-references using envsubst
    envsubst < .env > .env.tmp
    source .env.tmp
    rm .env.tmp
else
    echo "ABORTING: .env file not found!"
    exit
fi

if [ -f ./unulearner-resources/nginx/conf.template/default.conf.template ]; then
    mkdir -p nginx/conf.d/
    sudo chmod -R o+w ./nginx

    envsubst < ./unulearner-resources/nginx/conf.template/default.conf.template > ./nginx/conf.d/default.conf
    echo "Success: nginx configuration ready!"
else
    echo "ABORTING: nginx configuration failed! (template file not found)"
    exit
fi

if [ -f ./unulearner-resources/pgadmin/servers.json.template ]; then
    mkdir -p pgadmin/var/lib/pgadmin/sessions
    sudo chmod -R o+w ./pgadmin

    envsubst < ./unulearner-resources/pgadmin/servers.json.template > ./pgadmin/servers.json
    echo "Success: pgadmin servers configuration ready!"
else
    echo "ABORTING: pgadmin configuration failed! (template file not found)"
    exit
fi

# Create rest of the local directories
mkdir -p postgresdb/data
sudo chmod -R o+w ./postgresdb

# Pull unulearner repositories
if [ -d "$unulearner_frontend_path" ]; then
    echo "Folder '$unulearner_frontend_path' exists, meaning the repository has already been cloned locally!"
    echo "Would you like remove the existing local repository and clone it again? [y/N]: "
    
    read confirmation
    confirmation_lower=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [ "$confirmation_lower" = "y" ]; then
        rm -rf $unulearner_frontend_path
        git clone https://github.com/vipolar/unulearner-frontend.git
    else
        echo "Cloning repository skipped"
    fi
else
    git clone https://github.com/vipolar/unulearner-frontend.git
fi

# Launch
sudo docker compose up --build