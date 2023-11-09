# Create local files
mkdir -p pgadmin/var/lib/pgadmin/sessions
echo "{}" > pgadmin/servers.json
mkdir postgresdb

# Modify permissions
sudo chown -R unulearner:unulearner ./pgadmin
sudo chmod -R o+w ./pgadmin
sudo chown -R unulearner:unulearner ./postgresdb
sudo chmod -R o+w ./postgresdb

# Pull unulearner packages
git clone https://github.com/vipolar/unulearner-frontend.git

# Launch
sudo docker compose up --build