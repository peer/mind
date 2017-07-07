set -e

apt-get update -q -q
apt-get install --yes --force-yes build-essential python zlib1g-dev zlib1g git

rm -rf /source/.meteor/storage

cd /source
echo "module.exports = '$(git describe --always --dirty=+)'" > /source/packages/core/gitversion.coffee
