sudo docker compose down --volumes
sudo docker system prune #-a -f #NUCLEAR OPTION!
sudo docker volume rm $(sudo docker volume ls -q --filter dangling=true)

# Delete local files
sudo rm -rf pgadmin
sudo rm -rf postgresdb
