echo "docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle"
docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle

echo "docker-compose build"
docker-compose build

echo "docker-compose run app rails webpacker:install"
docker-compose run app rails webpacker:install

echo "set check_yarn_integrity: false"
sed -ie 's/check_yarn_integrity: true/check_yarn_integrity: false/g' config/webpacker.yml
# echo "docker-compose run app yarn add webpack-dev-server"
# docker-compose run app yarn add webpack-dev-server

echo "copy config files"
mv setup_files/copy_database.yml config/database.yml 
rmdir setup_files

echo "docker-compose run app rake db:create"
docker-compose run app rake db:create

