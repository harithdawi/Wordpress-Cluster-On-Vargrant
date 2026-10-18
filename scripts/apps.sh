#!/bin/bash
set -euo pipefail

# 1. Install client and dependencies
dnf install -y mysql php-cli php-json php-mysqli php-curl php-dom php-mbstring php-xml php-zip

# 2. Set variables
DB_HOST="192.168.56.41"
CRED_FILE="/root/data/wp-user-credentials.txt"
INFO_FILE="/root/data/wp-db-info.txt"
WP_PATH="/usr/share/nginx/html"

# 3. Load database credentials
if [ -f "$CRED_FILE" ]; then
    source "$CRED_FILE"
else
    echo "ERROR: File $CRED_FILE missing."
    exit 1
fi

# 4. Get local ip for wp
WP_IP=$(ip -4 addr show dev eth1 | awk '/inet / {print $2}' | cut -d/ -f1)
WP_URL="http://${WP_IP}"

# 5. Generate WP admin credentials
WP_ADMIN_USER="admin$(openssl rand -hex 3)"
WP_ADMIN_PASS="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 20)@1A"
WP_ADMIN_EMAIL="harith@dataspeed.com.my"

# 6. Install wp-cli
if [ ! -f /usr/local/bin/wp ]; then
    curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    chmod +x /usr/local/bin/wp
fi

# 7. Clean and prepare WordPress directory
mkdir -p "$WP_PATH"
rm -rf "${WP_PATH:?}"/*
cd "$WP_PATH"

# 8. Download WordPress core (Dibuang --skip-content supaya tema default dimasukkan sekali)
php -d memory_limit=512M /usr/local/bin/wp core download \
    --path="$WP_PATH" \
    --locale=en_US \
    --force \
    --allow-root

# 9. Create wp-config.php
/usr/local/bin/wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="$DB_HOST" \
    --path="$WP_PATH" \
    --force \
    --allow-root

# 10. Clean database tables if existing
/usr/local/bin/wp db reset --yes --path="$WP_PATH" --allow-root || true

# 11. Install WordPress database tables & admin user
/usr/local/bin/wp core install \
    --path="$WP_PATH" \
    --url="$WP_URL" \
    --title="WordPress Dev" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root

# 12. Save credentials
cat > "$INFO_FILE" <<EOF
WordPress URL=${WP_URL}

DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_HOST=${DB_HOST}

WP_ADMIN_USER=${WP_ADMIN_USER}
WP_ADMIN_PASS=${WP_ADMIN_PASS}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
EOF
chmod 600 "$INFO_FILE"


# 13. redis config on wp
cd /usr/share/nginx/html/
/usr/local/bin/wp plugin install redis-cache --activate --allow-root
/usr/local/bin/wp config set WP_REDIS_HOST "192.168.56.30" --allow-root
/usr/local/bin/wp config set WP_REDIS_PASSWORD "rediskucantik!2026" --allow-root
/usr/local/bin/wp config set WP_REDIS_PORT 6379 --raw --allow-root
/usr/local/bin/wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root
/usr/local/bin/wp config set WP_REDIS_READ_TIMEOUT 1 --raw --allow-root
/usr/local/bin/wp redis enable --allow-root
