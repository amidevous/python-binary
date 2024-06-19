#!/usr/bin/env bash

set -xe

VERNIM=2.7
VERS=2.7.18
TARGET=/usr/local/python$VERNIM
TARGET_ARCHIVE_DIR=/app/build
TARGET_ARCHIVE_PATH=${TARGET_ARCHIVE_DIR}/python$VERNIM-$(uname -m).tar.gz

#actual RHEL 8 + (and fork)/Fedroa 21 +
if test -f "/usr/bin/dnf"; then
    sudo dnf groupinstall -y "Development tools" "C Development Tools and Libraries"
    sudo dnf install -y wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel libdb-devel libpcap-devel xz-devel expat-devel
fi
#obsolete CentOS 6/7
if test -f "/usr/bin/yum"; then
    sudo yum groupinstall -y "Development tools" "C Development Tools and Libraries"
    sudo yum install -y wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel expat-devel
fi
#OpenSuse
if test -f "/usr/bin/zypper"; then
    sudo zypper install --type pattern devel_basis -y
    sudo zypper install -y wget zlib-devel bzip2 bzip3-devel libopenssl-devel ncurses-devel sqlite3-devel readline-devel tk-devel gdbm-devel libdb-4_8-devel libpcap-devel xz-devel libexpat-devel
fi
#Ubuntu/Debian
if test -f "/usr/bin/apt-get"; then
    sudo apt-get install debhelper cdbs lintian build-essential fakeroot devscripts dh-make dput -y
    sudo apt-get install -y wget zlib1g-dev bzip2 lbzip2 librust-bzip2-dev librust-bzip2-sys-dev libssl-dev ncurses-base ncurses-bin libncurses-dev sqlite3 libsqlite3-dev readline-common libreadline-dev tk-dev libgdbm-dev libdb-dev libpcap-dev xz-utils libexpat1-dev
fi
#for Cygwin (windows)
if test -f "/usr/bin/wget.exe"; then
    if [[ $(uname -m) == x86_64 ]]; then
        wget "https://cygwin.com/setup-x86_64.exe" -O setup-x86_64.exe
        chmod +x setup-x86_64.exe
        ./setup-x86_64.exe -P "autoconf,automake,binutils,bison,flex,gcc-core,gcc-g++,libgdbm-devel,libc++-devel,libtool,make,pkgconf,gettext,gettext-devel,doxygen,git,patch,patchutils,subversion,wget,zlib-devel,bzip2,lbzip2,libssl-devel,linncurses-devel,sqlite3,libsqlite3-devel,libreadline-devel,libfltk-devel,libdb-devel,xz,libexpat-devel" -q -R $(cygpath -w /) -l $(cygpath -w /)\var\cache\apt\packages --no-shortcuts --no-startmenu --arch x86_64 --no-write-registry --only-site --site https://mirrors.kernel.org/sourceware/cygwin/
        rm -f setup-x86_64.exe
cat > /usr/bin/sudo <<EOF
echo "sudo command not found for cygwin"
\$@
EOF
        chmod +x /usr/bin/sudo
    else
        wget "https://cygwin.com/setup-x86.exe" -O setup-x86.exe
        chmod +x setup-x86.exe
        ./setup-x86.exe -P "autoconf,automake,binutils,bison,flex,gcc-core,gcc-g++,libgdbm-devel,libc++-devel,libtool,make,pkgconf,gettext,gettext-devel,doxygen,git,patch,patchutils,subversion,wget,zlib-devel,bzip2,lbzip2,libssl-devel,linncurses-devel,sqlite3,libsqlite3-devel,libreadline-devel,libfltk-devel,libdb-devel,xz,libexpat-devel" -q -R $(cygpath -w /) -l $(cygpath -w /)\var\cache\apt\packages --no-shortcuts --no-startmenu --arch x86 --no-write-registry --no-verify --allow-unsupported-windows --only-site --site https://mirrors.kernel.org/sourceware/cygwin-archive/20221123/
        rm -f setup-x86.exe
cat > /usr/bin/sudo <<EOF
echo "sudo command not found for cygwin"
\$@
EOF
        chmod +x /usr/bin/sudo
    fi
fi

cd /tmp
wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.2n.tar.gz
tar -xzf openssl-*.tar.gz
cd openssl-1.0.2n
./config --prefix=/usr/local/openssl shared
make
sudo make install
mkdir -vp ${TARGET}

cd /tmp
wget --no-check-certificate https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz
tar -xzf Python-$VERS.tgz
cd Python-$VERS
./configure --prefix=${TARGET} --with-thread --enable-unicode=ucs4 --enable-shared --enable-ipv6 --with-system-expat --with-system-ffi --with-signal-module
echo "SSL=/usr/local/openssl" > Modules/Setup.local
make
if test -f "/usr/bin/wget.exe"; then
    make install
    rm -rf ${TARGET}/lib/python$VERNIM/test
    cd ${TARGET}/lib
    cp -av /usr/local/openssl/lib/*dll* .
    cp -av /usr/local/openssl/lib/engines .
    ln -vsf libcrypto.dll.1.0.0 libcrypto.dll.6
    ln -vsf libssl.dll.1.0.0 libssl.dll.6


    find /usr -name 'libdb*.dll' -exec cp -av {} . \;
    find /usr -name 'libreadline*.dll*' -exec cp -av {} . \;
    find /usr -name 'libbz2*.dll*' -exec cp -av {} . \;
    find /usr -name 'libcrypt*.dll*' -exec cp -av {} . \;
    find /usr -name 'libgdbm*.dll*' -exec cp -av {} . \;
    find /usr -name 'libsqlite*.dll*' -exec cp -av {} . \;
    find /usr -name 'libz*.dll*' -exec cp -av {} . \;
    find /usr -name 'libsqlite*.dll*' -exec cp -av {} . \;
    find /usr -name 'libncursesw*.dll*' -exec cp -av {} . \;

    find * -maxdepth 0 -name "*.dll" -exec strip {} \;
else
    sudo make install
    sudo rm -rf ${TARGET}/lib/python$VERNIM/test
    cd ${TARGET}/lib
    sudo cp -av /usr/local/openssl/lib/*so* .
    sudo cp -av /usr/local/openssl/lib/engines .
    sudo ln -vsf libcrypto.so.1.0.0 libcrypto.so.6
    sudo ln -vsf libssl.so.1.0.0 libssl.so.6


    sudo find /usr -name 'libdb*.so' -exec cp -av {} . \;
    sudo /usr -name 'libreadline*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libbz2*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libcrypt*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libgdbm*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libsqlite*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libz*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libsqlite*.so*' -exec cp -av {} . \;
    sudo find /usr -name 'libncursesw*.so*' -exec cp -av {} . \;

    sudo find * -maxdepth 0 -name "*.so" -exec strip {} \;
fi


#wget https://bootstrap.pypa.io/get-pip.py

cd ${TARGET}/bin
sudo ln -svf python2 python

export LD_LIBRARY_PATH=${TARGET}/lib
sudo ${TARGET}/bin/python /app/get-pip.py

sudo ln -svf pip2 pip

sudo ${TARGET}/bin/pip install virtualenv

sudo mkdir -vp ${TARGET_ARCHIVE_DIR}

sudo rm -vf ${TARGET_ARCHIVE_PATH}

sudo tar -czf ${TARGET_ARCHIVE_PATH} ${TARGET}
