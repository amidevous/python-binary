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
    sudo dnf install -y dnf-utils wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel libdb-devel libpcap-devel xz-devel expat-devel
    sudo dnf build-dep -y https://git.centos.org/rpms/python27-python/raw/c7/f/SPECS/python.spec
fi
#obsolete CentOS 6/7
if test -f "/usr/bin/yum"; then
    sudo yum groupinstall -y "Development tools" "C Development Tools and Libraries"
    sudo yum install -y yum-utils wget ca-certificates zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel expat-devel
    # security update rhel 6 backport to CentOS 6 ca-certificate 2021
    if [[ $(rpm -q ca-certificates) != "ca-certificates-2023.2.60_v7.0.306-72.el7_9.noarch" || $(rpm -q ca-certificates) != "ca-certificates-2020.2.41-65.1.el6.noarch"  ]]; then
        sudo yum -y install asciidoc libxslt java-devel libtasn1-devel libffi-devel gtk-doc lksctp-tools-devel db4-devel tcsh systemtap-sdt-devel chrpath
        rpmbuild --rebuild https://ftp.redhat.com/redhat/linux/enterprise/6Server/en/os/SRPMS/ca-certificates-2020.2.41-65.1.el6_10.src.rpm
        find $(rpm --eval '%_rpmdir') -name 'ca-certificates*.noarch.rpm' -exec sudo yum -y install {} \;
        find $(rpm --eval '%_topdir') -name '*ca-certificates*' -exec rm -rf {} \;
        rm -f ca-certificates-2020.2.41-65.1.el6_10.src.rpm
    fi
    wget https://git.centos.org/rpms/python27-python/raw/c7/f/SPECS/python.spec -O python.spec
    sudo yum-builddep -y python.spec
    rm -f python.spec
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
wget https://www.openssl.org/source/openssl-1.0.2n.tar.gz -O /tmp/openssl-1.0.2n.tar.gz
tar -xzf /tmp/openssl-1.0.2n.tar.gz
rm -f /tmp/openssl-1.0.2n.tar.gz
cd /tmp/openssl-1.0.2n
./config --prefix=/usr/local/openssl shared
make
sudo make install
mkdir -vp ${TARGET}

cd /tmp
rm -rf /tmp/openssl-1.0.2n
wget https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz -O /tmp/Python-$VERS.tgz
rm -rf /tmp/Python-$VERS
tar -xzf /tmp/Python-$VERS.tgz
rm -f /tmp/Python-$VERS.tgz
if test -f "/usr/bin/wget.exe"; then
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.5.2-ctypes-util-find_library.patch -O /tmp/2.5.2-ctypes-util-find_library.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.5.2-tkinter-x11.patch -O /tmp/2.5.2-tkinter-x11.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.6.5-FD_SETSIZE.patch -O /tmp/2.6.5-FD_SETSIZE.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.6.5-export-PySignal_SetWakeupFd.patch -O /tmp/2.6.5-export-PySignal_SetWakeupFd.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.6.5-ncurses-abi6.patch -O /tmp/2.6.5-ncurses-abi6.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.13-ftm.patch -O /tmp/2.7.13-ftm.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.17-use-rpm-wheels.patch -O /tmp/2.7.17-use-rpm-wheels.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.18-socketmodule.patch -O /tmp/2.7.18-socketmodule.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.3-dbm.patch -O /tmp/2.7.3-dbm.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.3-dylib.patch -O /tmp/2.7.3-dylib.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.3-getpath-exe-extension.patch -O /tmp/2.7.3-getpath-exe-extension.patch
wget https://www.cygwin.com/cgit/cygwin-packages/python2/plain/2.7.3-no-libm.patch -O /tmp/2.7.3-no-libm.patch
cd /tmp/Python-$VERS
patch -p2 </tmp/2.5.2-ctypes-util-find_library.patch
rm -rf /tmp/2.5.2-ctypes-util-find_library.patch
patch -p2 </tmp/2.5.2-tkinter-x11.patch
rm -rf /tmp/2.5.2-tkinter-x11.patch
patch -p1 </tmp/2.6.5-FD_SETSIZE.patch
rm -rf /tmp/2.6.5-FD_SETSIZE.patch
patch -p2 </tmp/2.6.5-export-PySignal_SetWakeupFd.patch
rm -rf /tmp/2.6.5-export-PySignal_SetWakeupFd.patch
patch -p2 </tmp/2.6.5-ncurses-abi6.patch
rm -rf /tmp/2.6.5-ncurses-abi6.patch
rm -f setup.py.orig
patch -p2 -f </tmp/2.7.3-dbm.patch setup.py
rm -rf /tmp/2.7.3-dbm.patch
patch -p2 -f </tmp/2.7.3-dylib.patch Lib/distutils/unixccompiler.py
rm -rf /tmp/2.7.3-dylib.patch
patch -p2 -f </tmp/2.7.3-getpath-exe-extension.patch Modules/getpath.c
rm -rf /tmp/2.7.3-getpath-exe-extension.patch
patch -p2 -f </tmp/2.7.3-no-libm.patch setup.py
rm -rf /tmp/2.7.3-no-libm.patch
patch -p2 </tmp/2.7.13-ftm.patch
rm -rf /tmp/2.7.13-ftm.patch
patch -p2 </tmp/2.7.17-use-rpm-wheels.patch
rm -rf /tmp/2.7.17-use-rpm-wheels.patch
patch -p2 </tmp/2.7.18-socketmodule.patch
rm -rf /tmp/2.7.18-socketmodule.patch
else
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7.1-config.patch -O /tmp/python-2.7.1-config.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00001-pydocnogui.patch -O /tmp/00001-pydocnogui.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.5-cflags.patch -O /tmp/python-2.5-cflags.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.5.1-plural-fix.patch -O /tmp/python-2.5.1-plural-fix.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.5.1-sqlite-encoding.patch -O /tmp/python-2.5.1-sqlite-encoding.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7rc1-binutils-no-dep.patch -O /tmp/python-2.7rc1-binutils-no-dep.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7rc1-socketmodule-constants.patch -O /tmp/python-2.7rc1-socketmodule-constants.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.6-rpath.patch -O /tmp/python-2.6-rpath.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.6.4-distutils-rpath.patch -O /tmp/python-2.6.4-distutils-rpath.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00055-systemtap.patch -O /tmp/00055-systemtap.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7.3-lib64.patch -O /tmp/python-2.7.3-lib64.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7-lib64-sysconfig.patch -O /tmp/python-2.7-lib64-sysconfig.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00104-lib64-fix-for-test_install.patch -O /tmp/00104-lib64-fix-for-test_install.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00111-no-static-lib.patch -O /tmp/00111-no-static-lib.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7.3-debug-build.patch -O /tmp/python-2.7.3-debug-build.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00113-more-configuration-flags.patch -O /tmp/00113-more-configuration-flags.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00114-statvfs-f_flag-constants.patch -O /tmp/00114-statvfs-f_flag-constants.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00121-add-Modules-to-build-path.patch -O /tmp/00121-add-Modules-to-build-path.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/python-2.7.2-add-extension-suffix-to-python-config.patch -O /tmp/python-2.7.2-add-extension-suffix-to-python-config.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00131-disable-tests-in-test_io.patch -O /tmp/00131-disable-tests-in-test_io.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00132-add-rpmbuild-hooks-to-unittest.patch -O /tmp/00132-add-rpmbuild-hooks-to-unittest.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00133-skip-test_dl.patch -O /tmp/00133-skip-test_dl.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00135-skip-test-within-test_weakref-in-debug-build.patch -O /tmp/00135-skip-test-within-test_weakref-in-debug-build.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00136-skip-tests-of-seeking-stdin-in-rpmbuild.patch -O /tmp/00136-skip-tests-of-seeking-stdin-in-rpmbuild.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00137-skip-distutils-tests-that-fail-in-rpmbuild.patch -O /tmp/00137-skip-distutils-tests-that-fail-in-rpmbuild.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00138-fix-distutils-tests-in-debug-build.patch -O /tmp/00138-fix-distutils-tests-in-debug-build.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00139-skip-test_float-known-failure-on-arm.patch -O /tmp/00139-skip-test_float-known-failure-on-arm.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00140-skip-test_ctypes-known-failure-on-sparc.patch -O /tmp/00140-skip-test_ctypes-known-failure-on-sparc.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00142-skip-failing-pty-tests-in-rpmbuild.patch -O /tmp/00142-skip-failing-pty-tests-in-rpmbuild.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00143-tsc-on-ppc.patch -O /tmp/00143-tsc-on-ppc.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00144-no-gdbm.patch -O /tmp/00144-no-gdbm.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00146-hashlib-fips.patch -O /tmp/00146-hashlib-fips.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00147-add-debug-malloc-stats.patch -O /tmp/00147-add-debug-malloc-stats.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00155-avoid-ctypes-thunks.patch -O /tmp/00155-avoid-ctypes-thunks.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00156-gdb-autoload-safepath.patch -O /tmp/00156-gdb-autoload-safepath.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00165-crypt-module-salt-backport.patch -O /tmp/00165-crypt-module-salt-backport.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00167-disable-stack-navigation-tests-when-optimized-in-test_gdb.patch -O /tmp/00167-disable-stack-navigation-tests-when-optimized-in-test_gdb.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00169-avoid-implicit-usage-of-md5-in-multiprocessing.patch -O /tmp/00169-avoid-implicit-usage-of-md5-in-multiprocessing.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00170-gc-assertions.patch -O /tmp/00170-gc-assertions.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00173-workaround-ENOPROTOOPT-in-bind_port.patch -O /tmp/00173-workaround-ENOPROTOOPT-in-bind_port.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00174-fix-for-usr-move.patch -O /tmp/00174-fix-for-usr-move.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00180-python-add-support-for-ppc64p7.patch -O /tmp/00180-python-add-support-for-ppc64p7.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00181-allow-arbitrary-timeout-in-condition-wait.patch -O /tmp/00181-allow-arbitrary-timeout-in-condition-wait.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00185-urllib2-honors-noproxy-for-ftp.patch -O /tmp/00185-urllib2-honors-noproxy-for-ftp.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00187-add-RPATH-to-pyexpat.patch -O /tmp/00187-add-RPATH-to-pyexpat.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00191-disable-NOOP.patch -O /tmp/00191-disable-NOOP.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00198-add-rewheel-module.patch -O /tmp/00198-add-rewheel-module.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00224-PEP-493-Re-add-file-based-configuration-of-HTTPS-ver.patch -O /tmp/00224-PEP-493-Re-add-file-based-configuration-of-HTTPS-ver.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00351-cve-2019-20907-fix-infinite-loop-in-tarfile.patch -O /tmp/00351-cve-2019-20907-fix-infinite-loop-in-tarfile.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00354-cve-2020-26116-http-request-method-crlf-injection-in-httplib.patch -O /tmp/00354-cve-2020-26116-http-request-method-crlf-injection-in-httplib.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00355-CVE-2020-27619.patch -O /tmp/00355-CVE-2020-27619.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00357-CVE-2021-3177.patch -O /tmp/00357-CVE-2021-3177.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00359-CVE-2021-23336.patch -O /tmp/00359-CVE-2021-23336.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00366-CVE-2021-3733.patch -O /tmp/00366-CVE-2021-3733.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00368-CVE-2021-3737.patch -O /tmp/00368-CVE-2021-3737.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00372-CVE-2021-4189.patch -O /tmp/00372-CVE-2021-4189.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00377-CVE-2022-0391.patch -O /tmp/00377-CVE-2022-0391.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/00378-support-expat-2-4-5.patch -O /tmp/00378-support-expat-2-4-5.patch
wget https://git.centos.org/rpms/python27-python/raw/c7/f/SOURCES/05000-autotool-intermediates.patch -O /tmp/05000-autotool-intermediates.patch
cd /tmp/Python-$VERS
patch -p1 </tmp/
rm -rf /tmp/
patch -p1 </tmp/
rm -rf /tmp/
fi
./configure --prefix=${TARGET} --with-thread --enable-unicode=ucs4 --enable-shared --enable-ipv6 --with-system-expat --with-system-ffi --with-signal-module
echo "SSL=/usr/local/openssl" > Modules/Setup.local
make
if test -f "/usr/bin/wget.exe"; then
    make altinstall
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
    sudo make altinstall
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



cd ${TARGET}/bin
rm -rf /tmp/Python-$VERS
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py -O get-pip.py
sudo ln -svf python2 python

export LD_LIBRARY_PATH=${TARGET}/lib
sudo ${TARGET}/bin/python get-pip.py

sudo ln -svf pip2 pip

sudo ${TARGET}/bin/pip install virtualenv

sudo mkdir -vp ${TARGET_ARCHIVE_DIR}

sudo rm -vf ${TARGET_ARCHIVE_PATH}

sudo tar -czf ${TARGET_ARCHIVE_PATH} ${TARGET}
