#!/usr/bin/env bash
SECONDS=0

MAGENTO_VERSION="2.3.5"
MAGENTO_REPO_URL="https://repo.magento.com/ magento/project-community-edition="${MAGENTO_VERSION}
PROJECT_PATH="www/html/magento"

echo " \033[93m Creating project path:  ${PROJECT_PATH}  \033[0m "
rm -rf www
mkdir -p ${PROJECT_PATH}
echo "\033[95m Building docker images...  \033[0m"
docker-compose build --no-cache -T
echo " \033[95m Building docker containers...  \033[0m "
docker-compose up -d
docker cp 000-default.conf magento-web:/etc/apache2/sites-enabled/
#docker cp index.php magento-web:/var/www/html/magento/
echo " \033[93m Setting up Magento CE ${MAGENTO_VERSION} ... \033[0m "
echo " \033[93m ...Installing magento   \033[0m "
docker exec magento-web bash -c " \
cd /var/www/html && wget https://github.com/magento/magento2/archive/2.3.5-p2.tar.gz && tar -xzf 2.3.5-p2.tar.gz && cp -r  magento2-2.3.5-p2/* magento
chmod -R 777 /var/www/html/magento &&
cd /var/www/html/magento && 
composer update && 
rm -rf app/etc/env.php && 
php bin/magento setup:install --admin-firstname=Admin --admin-lastname=User --admin-email=test@test.com --admin-user=admin --admin-password=admin123 --base-url=http://mystore.com:8030 --base-url-secure=https://mystore.com:8030 --backend-frontname=admin --db-host=mysql-magento --db-name=magento --db-user=root --db-password=root --use-rewrites=1 --language=en_US --currency=USD --timezone=America/New_York --admin-use-security-key=0 --session-save=files --use-sample-data;
cd /var/www/html/magento && 
php bin/magento cache:flush &&
php bin/magento cache:clean;" -d
echo '127.0.0.1   mystore.com' >> /cygdrive/c/Windows/System32/drivers/etc/hosts
docker cp .htaccess magento-web:/var/www/html/magento/
docker cp Apptha magento-web:/var/www/html/magento/app/code/
docker cp Ncb magento-web:/var/www/html/magento/app/design/frontend/
echo " \033[93m ...Reset magento permissions   \033[0m "
docker exec magento-web bash -c " \
cd /var/www/html/magento && chmod -R 777 * && bin/magento s:up && bin/magento s:d:c && bin/magento s:s:d -f && bin/magento c:f && chmod -R 777 *"

echo " \033[93m Restart web application server.... \033[0m "
docker container restart magento-web
docker exec -it mysql-magento mysql -uroot -proot -e" \
USE magento;
INSERT INTO core_config_data (config_id,scope,scope_id,path,value)
VALUES 
  (NULL, 'default', 0, 'design/theme/theme_id', (SELECT theme_id FROM theme WHERE code = 'Ncb/ncb-theme'))"
docker exec magento-web bash -c " \
cd /var/www/html/magento && rm -rf pub/static/frontend && rm -rf var/view_preprocessing && m -rf var/cache &&m -rf var/page_cache && php bin/magento cache:flush && chmod -R 777 *"
echo " \033[92m ...Magento- successfully installed and ready to use.  \033[0m "

duration=$SECONDS
echo "\033[91m Installation time: $(($duration / 60)) minutes and $(($duration % 60)) seconds  \033[0m "