#!/bin/sh -e

# There are two ways:
#
# 1) fetch https://raw.githubusercontent.com/A-E-3/ae3-install-utility/master/sh-scripts/install-freebsd.sh -o - | sh -e
# or
# 2) To execute this as a script, run:
#		sh -c 'eval "`cat`"'
# on the target machine under the 'root' user, paste whole text from this file, then press CTRL+D.
#

echo 'AE3 BSD Installer started...'

#
# Check user
#
test `id -u` != 0 && echo 'ERROR: Must be root!' && exit 1

######################################
if [ -d "/usr/local/myx.distro/local-deploy-cache" ] ; then
	export ENV_FETCH_LOCAL_CACHE="/usr/local/myx.distro/local-deploy-cache"
fi

fetch https://raw.githubusercontent.com/myx/os-myx.common/master/sh-scripts/install-myx.common.sh -o - | sh -e

myx.common lib/fetchStdout https://github.com/A-E-3/ae3-install-utility/archive/master.tar.gz | \
		tar zxvf - -C "/usr/local/" --include "*/host/tarball/*" --include "*/host-freebsd/tarball/*" --strip-components 3

myx.common lib/installUser ae3 "AE3 pseudo-user" 173 /usr/local/ae3

######################################

AE3_BIN="/usr/local/bin/ae3"

chown root:ae3 "$AE3_BIN"
chmod 755 "$AE3_BIN"

######################################

AE3_SHR="/usr/local/share/ae3"

chown -R root:ae3 "$AE3_SHR/bin"
chmod -R 750 "$AE3_SHR/bin"

######################################

AE3_DIR="/usr/local/ae3"

mkdir -p "$AE3_DIR/shared" "$AE3_DIR/private"

chown -R root:ae3 "$AE3_DIR/shared"
chmod -R 770 "$AE3_DIR/shared"

chown -R root:ae3 "$AE3_DIR/private"
chmod -R 770 "$AE3_DIR/private"

######################################

ETC_DIR="/usr/local/etc"

chown root:wheel "$ETC_DIR/rc.d/ae3d"
chmod 555 "$ETC_DIR/rc.d/ae3d"

chown root:wheel "$ETC_DIR/periodic/daily/403.ae3"
chmod 555 "$ETC_DIR/periodic/daily/403.ae3"

######################################

exec "$AE3_SHR/bin/reinstall"
