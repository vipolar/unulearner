#!/bin/bash

script_file="./$(basename "${BASH_SOURCE[0]}")"
unulearner_frontend_path="./unulearner-frontend"
unulearner_backend_path="./unulearner-backend"

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
    mkdir -p nginx/certbot/www
    mkdir -p nginx/server/logs
    mkdir -p nginx/letsencrypt/live
    mkdir -p nginx/letsencrypt/archive
    mkdir -p nginx/letsencrypt/accounts
    sudo chmod -R o+w ./nginx

    envsubst < ./unulearner-resources/nginx/conf.template/default.conf.template > ./nginx/conf.d/default.conf
    echo "Success: nginx configuration ready!"

    if [ -f ./unulearner-resources/nginx/healthcheck.sh ]; then
        cp ./unulearner-resources/nginx/healthcheck.sh ./nginx
        chmod +x ./nginx/healthcheck.sh 

        echo "Success: nginx healthcheck script installed successfully!"
    else
        echo "ERROR: nginx healthcheck script not found!"
    fi
else
    echo "ABORTING: nginx configuration failed! (template file not found)"
    exit
fi

if [ -f ./unulearner-resources/postgresdb/init-scripts/create-multiple-postgresql-databases.sh ]; then
    mkdir -p postgresdb/data
    mkdir -p postgresdb/config
    mkdir -p postgresdb/scripts
    sudo chmod -R o+w ./postgresdb

    cp ./unulearner-resources/postgresdb/init-scripts/create-multiple-postgresql-databases.sh ./postgresdb/scripts
    echo "Success: postgreSQL init script ready!"
else
    echo "ABORTING: postgreSQL init script not found!"
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

# Pull unulearner repositories
if [ -d "$unulearner_frontend_path" ]; then
    echo "Folder '$unulearner_frontend_path' exists, meaning the repository has already been cloned locally!"
    echo "Would you like remove the existing local repository and clone it again? [y/N]: "
    
    read confirmation
    confirmation_lower=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [ "$confirmation_lower" = "y" ]; then
        rm -rf $unulearner_frontend_path
        git clone https://github.com/vipolar/unulearner-frontend.git
        mkdir -p ./unulearner-frontend/.angular
        sudo chmod -R o+w ./unulearner-frontend/.angular
        mkdir -p ./unulearner-frontend/node_modules
        sudo chmod -R o+w ./unulearner-frontend/node_modules
    else
        echo "Cloning repository skipped"
    fi
else
    git clone https://github.com/vipolar/unulearner-frontend.git #DIRNAME
    mkdir -p ./unulearner-frontend/.angular
    sudo chmod -R o+w ./unulearner-frontend/.angular
    mkdir -p ./unulearner-frontend/node_modules
    sudo chmod -R o+w ./unulearner-frontend/node_modules
fi

# Launch
sudo docker compose up --build