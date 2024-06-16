#!/usr/bin/env bash

set -xe

VERNIM=3.5
VERS=3.5.10
TARGET=/usr/local/python$VERNIM
TARGET_ARCHIVE_DIR=/app/build
TARGET_ARCHIVE_PATH=${TARGET_ARCHIVE_DIR}/python$VERNIM-$(uname -m).tar.gz

#actual RHEL 8 + (and fork)/Fedroa 21 +
if test -f "/usr/bin/dnf"; then
    sudo dnf groupinstall -y "Development tools"
    sudo dnf install -y wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel libdb-devel libpcap-devel xz-devel expat-devel
fi
#obsolete CentOS 6/7
if test -f "/usr/bin/yum"; then
    sudo yum groupinstall -y "Development tools"
    sudo yum install -y wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel expat-devel
fi
#OpenSuse
if test -f "/usr/bin/zypper"; then
    sudo zypper install --type pattern devel_basis -y
    sudo zypper install -y wget zlib-devel bzip2 bzip3-devel libopenssl-devel ncurses-devel sqlite3-devel readline-devel tk-devel gdbm-devel libdb-4_8-devel libpcap-devel xz-devel libexpat-devel
fi
#Ubuntu/Debian
if test -f "/usr/bin/apt-get"; then
    sudo zypper install --type pattern devel_basis -y
    sudo apt-get install -y wget zlib1g-dev bzip2 lbzip2 librust-bzip2-dev librust-bzip2-sys-dev libssl-dev ncurses-base ncurses-bin libncurses-dev sqlite3 libsqlite3-dev readline-common libreadline-dev tk-dev libgdbm-dev libdb-dev libpcap-dev xz-utils libexpat1-dev
fi

cd /tmp
wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.2n.tar.gz
tar -xzf openssl-*.tar.gz
cd openssl-*
./config --prefix=/usr/local/openssl shared
make
sudo make install

mkdir -vp ${TARGET}

cd /tmp
wget --no-check-certificate https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz
tar -xzf Python-*.tgz
cd Python-*
./configure --prefix=${TARGET} --with-thread --enable-unicode=ucs4 --enable-shared --enable-ipv6 --with-system-expat --with-system-ffi --with-signal-module
echo "SSL=/usr/local/openssl" > Modules/Setup.local
make
sudo make install

sudo rm -rf ${TARGET}/lib/python$VERNIM/test

cd ${TARGET}/lib

sudo cp -av /usr/local/openssl/lib/*so* .
sudo cp -av /usr/local/openssl/lib/engines .
sudo ln -vsf libcrypto.so.1.0.0 libcrypto.so.6
sudo ln -vsf libssl.so.1.0.0 libssl.so.6


sudo find /usr -name 'libdb*.so' -exec cp -av {} . \;
find /usr -name 'libreadline*.so*' -exec cp -av {} . \;
find /usr -name 'libbz2*.so*' -exec cp -av {} . \;
find /usr -name 'libcrypt*.so*' -exec cp -av {} . \;
find /usr -name 'libgdbm*.so*' -exec cp -av {} . \;
find /usr -name 'libsqlite*.so*' -exec cp -av {} . \;
find /usr -name 'libz*.so*' -exec cp -av {} . \;
find /usr -name 'libsqlite*.so*' -exec cp -av {} . \;
find /usr -name 'libncursesw*.so*' -exec cp -av {} . \;

find * -maxdepth 0 -name "*.so" -exec strip {} \;

#wget https://bootstrap.pypa.io/get-pip.py

cd ${TARGET}/bin
ln -svf python3 python

LD_LIBRARY_PATH=${TARGET}/lib ${TARGET}/bin/python /app/get-pip.py

ln -svf pip3 pip

LD_LIBRARY_PATH=${TARGET}/lib ${TARGET}/bin/pip install virtualenv

mkdir -vp ${TARGET_ARCHIVE_DIR}

rm -vf ${TARGET_ARCHIVE_PATH}

tar -czf ${TARGET_ARCHIVE_PATH} ${TARGET}
