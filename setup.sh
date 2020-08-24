#!/bin/bash

##### options #####
opptinal_packages=true

install_Bootstrap=true
install_FontAwesome=true
###################

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
echo 'import "../stylesheets/application.scss";' >> app/javascript/packs/application.js


if "$opptinal_packages" ; then
if "$install_Bootstrap" ; then
echo "install Bootstrap"
docker-compose run app yarn add bootstrap jquery popper.js --ignore-optional
echo 'require("bootstrap");' >> app/javascript/packs/application.js
echo '@import "bootstrap/scss/bootstrap";' >> app/javascript/stylesheets/application.scss
mv temp_files/copy_environment.js config/webpack/environment.js
fi

if "$install_FontAwesome" ; then
echo "install Font Awesome"
docker-compose run app yarn add @fortawesome/fontawesome-free
echo 'require("@fortawesome/fontawesome-free");' >> app/javascript/packs/application.js
echo 'import "@fortawesome/fontawesome-free/js/all";' >> app/javascript/packs/application.js
echo '@import "@fortawesome/fontawesome-free/scss/fontawesome";' >> app/javascript/stylesheets/application.scss
fi

docker-compose build
fi

echo "clean temp filse"
rm -r temp_files
rm config/webpacker.ymlcp



