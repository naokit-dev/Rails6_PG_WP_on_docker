#!/bin/bash

echo "docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle"
docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle

echo "docker-compose build"
docker-compose build

echo "docker-compose run app rails webpacker:install"
docker-compose run app rails webpacker:install

echo "set check_yarn_integrity: false"
sed -icp 's/check_yarn_integrity: true/check_yarn_integrity: false/g' config/webpacker.yml

echo "copy config files"
mv temp_files/copy_database.yml config/database.yml

echo "docker-compose run app rake db:create"
docker-compose run app rake db:create

echo "create CSS for Webpack"
mkdir app/javascript/stylesheets
touch app/javascript/stylesheets/application.scss
mv temp_files/copy_application.html.erb app/views/layouts/application.html.erb

echo "clean temp filse"
rm -r temp_files
rm config/webpacker.ymlcp



