#!/bin/bash

XCONFIGURE="--prefix=/usr --libdir=/usr/lib --libexecdir=/usr/lib --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --localstatedir=/var"

JOB_FACTOR=1
NUM_CORES=$(grep ^processor /proc/cpuinfo | wc -l)
NUM_JOBS=$((NUM_CORES * JOB_FACTOR))

DESTDIR=$PWD/rootfs
ROOTCD=$PWD/rootcd
STUFF=$PWD/stuff
READY=$PWD/ready
SRC=$PWD/src

rm -rf $DESTDIR $ROOTCD $READY $SRC
mkdir -p $DESTDIR $ROOTCD $READY $SRC

FLAGS="-fPIC -fdata-sections -ffunction-sections -Os -g0 -s -fno-unwind-tables -fno-asynchronous-unwind-tables -Wa,--noexecstack -fno-stack-protector -fomit-frame-pointer -U_FORTIFY_SOURCE"

build_base() {
	export CFLAGS="$FLAGS"
	export CXXFLAGS="$CFLAGS"

	cd $SRC
	wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.9.38.tar.xz
	tar -xf linux-4.9.38.tar.xz
	cd linux-4.9.38
	make mrproper -j $NUM_JOBS
	make distclean -j $NUM_JOBS
	cp $STUFF/kernel_config .config
	make oldconfig -j $NUM_JOBS
	make CFLAGS="$FLAGS" -j $NUM_JOBS
	make INSTALL_HDR_PATH=$DESTDIR/usr headers_install -j $NUM_JOBS
	make INSTALL_MOD_PATH=$DESTDIR modules_install -j $NUM_JOBS
	make INSTALL_FW_PATH=$DESTDIR/lib/firmware firmware_install -j $NUM_JOBS

	cd $SRC
	wget http://busybox.net/downloads/busybox-1.27.1.tar.bz2
	tar -xf busybox-1.27.1.tar.bz2
	cd busybox-1.27.1
	make distclean -j $NUM_JOBS
	make defconfig -j $NUM_JOBS
	sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
	make CONFIG_PREFIX=$DESTDIR install -j $NUM_JOBS
	rm -rf $DESTDIR/linuxrc
	cd $DESTDIR
	ln -s bin/busybox init

	cd $SRC
	wget http://www.musl-libc.org/releases/musl-1.1.16.tar.gz
	tar -xf musl-1.1.16.tar.gz
	cd musl-1.1.16
	./configure \
		$XCONFIGURE \
		--syslibdir=/lib \
		--enable-optimize=size
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz
	tar -xf acl-2.2.52.src.tar.gz
	cd acl-2.2.52
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DIST_ROOT=$DESTDIR install install-dev install-lib

	cd $SRC
	wget http://prdownloads.sourceforge.net/acpid2/acpid-2.0.28.tar.xz
	tar -xf acpid-2.0.28.tar.xz
	cd acpid-2.0.28
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.4.1.tar.bz2
	tar -xf alsa-lib-1.1.4.1.tar.bz2
	cd alsa-lib-1.1.4.1
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install
	
	cd $SRC
	wget ftp://ftp.alsa-project.org/pub/utils/alsa-utils-1.1.4.tar.bz2
	tar -xf alsa-utils-1.1.4.tar.bz2
	cd alsa-utils-1.1.4
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://download.savannah.gnu.org/releases/attr/attr-2.4.47.src.tar.gz
	tar -xf attr-2.4.47.src.tar.gz
	cd attr-2.4.47
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DIST_ROOT=$DESTDIR install install-dev install-lib

	cd $SRC
	wget http://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz
	tar -xf bash-4.4.tar.gz
	cd bash-4.4
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--with-installed-readline \
		--without-bash-malloc \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v4.11.1.tar.xz
	tar -xf btrfs-progs-v4.11.1.tar.xz
	cd btrfs-progs-v4.11.1
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
	tar -xf bzip2-1.0.6.tar.gz
	cd bzip2-1.0.6
	patch -Np1 -i $STUFF/bzip2.patch
	make -j $NUM_JOBS
	make PREFIX=$DESTDIR/usr install
	make -f Makefile-libbz2_so -j $NUM_JOBS
	make -f Makefile-libbz2_so PREFIX=$DESTDIR/usr install
  
	cd $SRC
	wget http://ftp.gnu.org/gnu/cpio/cpio-2.12.tar.bz2
	tar -xf cpio-2.12.tar.bz2
	cd cpio-2.12
	./configure \
		$XCONFIGURE \
		--enable-mt \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://curl.haxx.se/download/curl-7.54.1.tar.bz2
	tar -xf curl-7.54.1.tar.bz2
	cd curl-7.54.1
	./configure \
		$XCONFIGURE \
		--enable-threaded-resolver \
		--disable-static \
		--enable-ipv6 \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz
	tar -xf db-6.2.32.tar.gz
	cd db-6.2.32
	./configure \
		$XCONFIGURE \
		--enable-compat185 \
		--enable-dbm \
		--disable-static \
		--enable-cxx \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://dbus.freedesktop.org/releases/dbus/dbus-1.10.20.tar.gz
	tar -xf dbus-1.10.20.tar.gz
	cd dbus-1.10.20
	./configure \
		$XCONFIGURE \
		--with-system-socket=/var/run/dbus/system_bus_socket \
		--with-system-pid-file=/var/run/messagebus.pid \
		--with-init-scripts=none \
		--with-dbus-user=dbus \
		--with-xml=expat \
		--without-x \
		--disable-tests \
		--disable-asserts \
		--disable-selinux \
		--disable-xml-docs \
		--disable-doxygen-docs \
		--disable-dnotify \
		--disable-libaudit \
		--disable-systemd \
		--enable-abstract-sockets \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://roy.marples.name/downloads/dhcpcd/dhcpcd-6.11.5.tar.xz
	tar -xf dhcpcd-6.11.5.tar.xz
	cd dhcpcd-6.11.5
	./configure \
		$XCONFIGURE \
		--os=linux \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install
	
	cd $SRC
	wget http://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.43.4/e2fsprogs-1.43.4.tar.gz
	tar -xf e2fsprogs-1.43.4.tar.gz
	cd e2fsprogs-1.43.4
	./configure \
		$XCONFIGURE \
		--with-root-prefix="" \
		--enable-elf-shlibs \
		--disable-libblkid \
		--disable-libuuid \
		--disable-uuidd \
		--disable-fsck \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install install-libs

	cd $SRC
	wget http://dev.gentoo.org/~blueness/eudev/eudev-3.2.2.tar.gz
	tar -xf eudev-3.2.2.tar.gz
	cd eudev-3.2.2
	./configure \
		$XCONFIGURE \
		--with-rootprefix= \
		--with-rootlibdir=/usr/lib  \
		--disable-introspection \
		--disable-manpages \
		--disable-selinux \
		--enable-kmod \
		--enable-blkid \
		--enable-hwdb \
		--enable-rule-generator \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://prdownloads.sourceforge.net/expat/expat-2.2.2.tar.bz2
	tar -xf expat-2.2.2.tar.bz2
	cd expat-2.2.2
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget ftp://ftp.astron.com/pub/file/file-5.31.tar.gz
	tar -xf file-5.31.tar.gz
	cd file-5.31
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://github.com/libfuse/libfuse/releases/download/fuse-3.1.0/fuse-3.1.0.tar.gz
	tar -xf fuse-3.1.0.tar.gz
	cd fuse-3.1.0
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://ftp.gnu.org/gnu/grub/grub-2.02.tar.xz
	tar -xf grub-2.02.tar.xz
	cd grub-2.02
	./configure \
		$XCONFIGURE \
		--enable-boot-time \
		--disable-werror \
		--disable-nls \
		--disable-liblzma \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install
	
	cd $SRC
	wget http://ftp.gnu.org/gnu/gzip/gzip-1.8.tar.xz
	tar -xf gzip-1.8.tar.xz
	cd gzip-1.8
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.12.0.tar.xz
	tar -xf iproute2-4.12.0.tar.xz
	cd iproute2-4.12.0
	sed -i /ARPD/d Makefile
	sed -i 's/arpd.8//' man/man8/Makefile
	rm -v doc/arpd.sgml
	sed -i 's/m_ipt.o//' tc/Makefile
	make CCOPTS="$FLAGS"
	make install \
		DESTDIR=$DESTDIR \
		MANDIR=/usr/share/man \
		LIBDIR=/usr/lib

	cd $SRC
	wget https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-24.tar.xz
	tar -xf kmod-24.tar.xz
	cd kmod-24
	./configure \
		$XCONFIGURE \
		--with-rootlibdir=/usr/lib \
		--with-xz \
		--with-zlib \
		--disable-manpages \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.libarchive.org/downloads/libarchive-3.3.2.tar.gz
	tar -xf libarchive-3.3.2.tar.gz
	cd libarchive-3.3.2
	./configure \
		$XCONFIGURE \
		--without-xml2 \
		--without-expat \
		--without-nettle \
		--without-openssl \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.25.tar.xz
	tar -xf libcap-2.25.tar.xz
	cd libcap-2.25
	sed -i "/^CFLAGS/s/-O2/$FLAGS/" Make.Rules 
	make
	make install \
		DESTDIR=$DESTDIR \
		LIBDIR=/usr/lib \
		SBINDIR=/usr/sbin \
		PKGCONFIGDIR=/usr/lib/pkgconfig \
		RAISE_SETFCAP=no

	cd $SRC
	wget https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
	tar -xf libevent-2.1.8-stable.tar.gz
	cd libevent-2.1.8-stable
	./configure \
		$XCONFIGURE \
		--disable-static \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
	tar -xf libffi-3.2.1.tar.gz
	cd libffi-3.2.1
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://ftp.barfooze.de/pub/sabotage/tarballs/libnl-tiny-1.0.1.tar.xz
	tar -xf libnl-tiny-1.0.1.tar.xz
	cd libnl-tiny-1.0.1
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.5.4.tar.gz
	tar -xf libressl-2.5.4.tar.gz
	cd libressl-2.5.4
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://github.com/libusb/libusb/releases/download/v1.0.21/libusb-1.0.21.tar.bz2
	tar -xf libusb-1.0.21.tar.bz2
	cd libusb-1.0.21
	./configure \
		$XCONFIGURE \
		--disable-udev \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://downloads.sourceforge.net/project/libusb/libusb-compat-0.1/libusb-compat-0.1.5/libusb-compat-0.1.5.tar.bz2
	tar -xf libusb-compat-0.1.5.tar.bz2
	cd libusb-compat-0.1.5
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget ftp://xmlsoft.org/libxml2/libxml2-2.9.4.tar.gz
	tar -xf libxml2-2.9.4.tar.gz
	cd libxml2-2.9.4
	./configure \
		$XCONFIGURE \
		--without-python \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget ftp://sources.redhat.com/pub/lvm2/releases/LVM2.2.02.172.tgz
	tar -xf LVM2.2.02.172.tgz
	cd LVM2.2.02.172
	./configure \
		$XCONFIGURE \
		--enable-write_install \
		--enable-pkgconfig \
		--enable-cmdlib \
		--enable-dmeventd \
		--disable-nls \
		--disable-readline \
		--disable-applib \
		--disable-selinux \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
	tar -xf lzo-2.10.tar.gz
	cd lzo-2.10
	./configure \
		$XCONFIGURE \
		--enable-shared \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.kernel.org/pub/linux/utils/raid/mdadm/mdadm-4.0.tar.xz
	tar -xf mdadm-4.0.tar.xz
	cd mdadm-4.0
	sed 's@-Werror@@' -i Makefile
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.nano-editor.org/dist/v2.8/nano-2.8.6.tar.xz
	tar -xf nano-2.8.5.tar.xz
	cd nano-2.8.5
	./configure \
		$XCONFIGURE \
		--enable-utf8 \
		--disable-nls \
		--disable-wrapping \
		--disable-nls \
		--with-wordbounds \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz
	tar -xf ncurses-6.0.tar.gz
	cd ncurses-6.0
	./configure \
		$XCONFIGURE \
		--with-shared \
		--without-debug \
		--without-normal \
		--enable-pc-files \
		--enable-widec \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://tuxera.com/opensource/ntfs-3g_ntfsprogs-2017.3.23.tgz
	tar -xf ntfs-3g_ntfsprogs-2017.3.23.tgz
	cd ntfs-3g_ntfsprogs-2017.3.23
	./configure \
		$XCONFIGURE \
		--with-fuse=internal \
		--disable-static \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2/ntp-4.2.8p10.tar.gz
	tar -xf ntp-4.2.8p10.tar.gz
	cd ntp-4.2.8p10
	./configure \
		$XCONFIGURE \
		--with-crypto \
		--enable-linuxcap \
		--enable-ipv6 \
		--enable-ntp-signd \
		--enable-all-clocks \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz
	tar -xf openssh-7.5p1.tar.gz
	cd openssh-7.5p1
	./configure \
		$XCONFIGURE \
		--with-privsep-path=/var/lib/sshd \
		--with-md5-passwords \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/software/utils/pciutils/pciutils-3.5.4.tar.xz
	tar -xf pciutils-3.5.4.tar.xz
	cd pciutils-3.5.4
	make \
		PREFIX=/usr \
		SHAREDIR=/usr/share/hwdata \
		SHARED=yes
	make \
		PREFIX=$DESTDIR/usr \
		SHAREDIR=/usr/share/hwdata \
		SHARED=yes \
		install install-lib

	cd $SRC
	wget https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz
	tar -xf pcre-8.41.tar.gz
	cd pcre-8.41
	./configure \
		$XCONFIGURE \
		--enable-unicode-properties \
		--enable-pcretest-libreadline \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2 \
		--enable-utf8 \
		--enable-jit \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://download.samba.org/pub/ppp/ppp-2.4.7.tar.gz
	tar -xf ppp-2.4.7.tar.gz
	cd ppp-2.4.7
	./configure \
		$XCONFIGURE \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz
	tar -xf readline-7.0.tar.gz
	cd readline-7.0
	./configure \
		$XCONFIGURE \
		--disable-static \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.samba.org/ftp/rsync/src/rsync-3.1.2.tar.gz
	tar -xf rsync-3.1.2.tar.gz
	cd rsync-3.1.2
	./configure \
		$XCONFIGURE \
		--without-included-zlib \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.sudo.ws/dist/sudo-1.8.20p2.tar.gz
	tar -xf sudo-1.8.20p2.tar.gz
	cd sudo-1.8.20p2
	./configure \
		$XCONFIGURE \
		--with-secure-path \
		--with-all-insults \
		--with-env-editor \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.draisberghof.de/usb_modeswitch/usb-modeswitch-2.5.0.tar.bz2
	tar -xf usb-modeswitch-2.5.0.tar.bz2
	cd usb-modeswitch-2.5.0
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/linux/utils/usb/usbutils/usbutils-008.tar.xz
	tar -xf usbutils-008.tar.xz
	cd usbutils-008
	./configure \
		$XCONFIGURE \
		--disable-usbids \
		--disable-zlib \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://www.kernel.org/pub/linux/utils/util-linux/v2.30/util-linux-2.30.tar.xz
	tar -xf util-linux-2.30.tar.xz
	cd util-linux-2.30
	./configure \
		$XCONFIGURE \
		--disable-uuidd \
		--disable-nls \
		--disable-tls \
		--disable-kill \
		--disable-login \
		--disable-last \
		--disable-sulogin \
		--disable-su \
		--without-python \
		--without-systemd \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://hewlettpackard.github.io/wireless-tools/wireless_tools.29.tar.gz
	tar -xf wireless_tools.29.tar.gz
	cd wireless_tools.29
	sed "s|CFLAGS=|CFLAGS=$FLAGS |" -i Makefile
	make -j $NUM_JOBS
	make PREFIX=$DESTDIR/usr install

	cd $SRC
	wget http://w1.fi/releases/wpa_supplicant-2.6.tar.gz
	tar -xf wpa_supplicant-2.6.tar.gz
	cd wpa_supplicant-2.6/wpa_supplicant
	cp $STUFF/wpa_config .config
	make BINDIR=/usr/sbin LIBDIR=/usr/lib -j $NUM_JOBS
	make DESTDIR=$DESTDIR BINDIR=/usr/sbin LIBDIR=/usr/lib install

	cd $SRC
	wget https://www.kernel.org/pub/linux/utils/fs/xfs/xfsprogs/xfsprogs-4.11.0.tar.xz
	tar -xf xfsprogs-4.11.0.tar.xz
	cd xfsprogs-4.11.0
	./configure \
		$XCONFIGURE \
		--disable-gettext \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget https://tukaani.org/xz/xz-5.2.3.tar.xz
	tar -xf xz-5.2.3.tar.xz
	cd xz-5.2.3
	./configure \
		$XCONFIGURE \
		--disable-nls \
		--disable-rpath \
		--disable-werror \
		CFLAGS="$FLAGS"
	make -j $NUM_JOBS
	make DESTDIR=$DESTDIR install

	cd $SRC
	wget http://www.zlib.net/zlib-1.2.11.tar.gz
	tar -xf zlib-1.2.11.tar.gz
	cd zlib-1.2.11
	./configure \
		--prefix=/usr \
		--libdir=/usr/lib \
		--shared
	make
	make DESTDIR=$DESTDIR install
}

build_image() {
find $DESTDIR -type f | xargs file 2>/dev/null | grep "LSB executable"     | cut -f 1 -d : | xargs strip --strip-all --strip-unneeded 2>/dev/null || true
find $DESTDIR -type f | xargs file 2>/dev/null | grep "shared object"      | cut -f 1 -d : | xargs strip --strip-all --strip-unneeded 2>/dev/null || true
find $DESTDIR -type f | xargs file 2>/dev/null | grep "current ar archive" | cut -f 1 -d : | xargs strip -g 

mkdir -p $ROOTCD/boot/isolinux

cp $SRC/linux-4.9.38/arch/x86/boot/bzImage $ROOTCD/bzImage

cd $DESTDIR
find | ( set -x; cpio -o -H newc | xz -9 --format=lzma --verbose --verbose ) > $ROOTCD/initrd.img
cd ..

cd $SRC
wget http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
tar -xf syslinux-6.03.tar.xz
cd ..

cp $SRC/syslinux-6.03/bios/core/isolinux.bin $ROOTCD/boot/isolinux/isolinux.bin
cp $SRC/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 $ROOTCD/boot/isolinux/ldlinux.c32

cat > $ROOTCD/boot/isolinux/isolinux.cfg << "EOF"
default boot
label boot
    kernel /bzImage
    append initrd=/initrd.img rw root=/dev/null vga=normal
implicit 0
prompt 1
timeout 80
EOF

mkdir -p $ROOTCD/efi/boot
cat > $ROOTCD/efi/boot/startup.nsh << "EOF"
echo -off
echo RAMIX is loading...
\\bzImage initrd=\\initrd.img
EOF

xorriso \
	-J -R -l -V "RAMIX" \
	-o $READY/ramix.iso \
	-b boot/isolinux/isolinux.bin \
	-c boot/isolinux/boot.cat \
	-input-charset UTF-8 \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	$ROOTCD
}

build_base
build_image

exit 0
