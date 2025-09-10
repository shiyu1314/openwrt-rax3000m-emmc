#!/bin/bash



sed -i "s/kmod-tcp-bbr/kmod-tcp-bbr3/" package/mtk/applications/luci-app-turboacc-mtk/Makefile

git clone -b packages --depth 1 --single-branch https://github.com/shiyu1314/openwrt-feeds package/xd
git clone -b porxy --depth 1 --single-branch https://github.com/shiyu1314/openwrt-feeds package/porxy


rm -rf feeds/luci/applications/{luci-app-dockerman,luci-app-samba4,luci-app-aria2}
rm -rf feeds/packages/{net/samba4,v2ray-geodata,mosdns,sing-box,aria2,ariang,adguardhome}



pushd feeds/luci
    patch -p1 < 0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch
    patch -p1 < 0002-luci-mod-status-displays-actual-process-memory-usage.patch
    patch -p1 < 0003-luci-mod-status-storage-index-applicable-only-to-val.patch
    patch -p1 < 0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch
    patch -p1 < 0005-luci-mod-system-add-refresh-interval-setting.patch
    patch -p1 < 0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch
    patch -p1 < 0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch
    patch -p1 < 0008-luci-mod-network-add-option-for-ipv6-max-plt-vlt.patch
    patch -p1 < 0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd

sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd-mod-ubus //' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci-light/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+uhttpd +uhttpd-mod-ubus /+luci-nginx /g' feeds/packages/net/wg-installer/Makefile
sed -i '/uhttpd-mod-ubus/d' feeds/luci/collections/luci-light/Makefile
sed -i 's/+luci-nginx \\$/+luci-nginx/' feeds/luci/collections/luci-light/Makefile



# nginx - latest version
rm -rf feeds/packages/net/nginx
git clone https://github.com/sbwml/feeds_packages_net_nginx feeds/packages/net/nginx -b openwrt-24.10
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g;s/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/net/nginx/files/nginx.init

# nginx - ubus
sed -i 's/ubus_parallel_req 2/ubus_parallel_req 6/g' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 300;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support


# uwsgi - fix timeout
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i '/limit-as/c\limit-as = 5000' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# disable error log
sed -i "s/procd_set_param stderr 1/procd_set_param stderr 0/g" feeds/packages/net/uwsgi/files/uwsgi.init

# uwsgi - performance
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini

# rpcd - fix timeout
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js



# openssl urandom
sed -i "/-openwrt/iOPENSSL_OPTIONS += enable-ktls '-DDEVRANDOM=\"\\\\\"/dev/urandom\\\\\"\"\'\n" package/libs/openssl/Makefile


# fstools
rm -rf package/system/fstools
git clone https://github.com/sbwml/package_system_fstools -b openwrt-24.10 package/system/fstools
# util-linux
rm -rf package/utils/util-linux
git clone https://github.com/sbwml/package_utils_util-linux -b openwrt-24.10 package/utils/util-linux


# openssl
OPENSSL_VERSION=3.0.17
OPENSSL_HASH=dfdd77e4ea1b57ff3a6dbde6b0bdc3f31db5ac99e7fdd4eaf9e1fbb6ec2db8ce
sed -ri "s/(PKG_VERSION:=)[^\"]*/\1$OPENSSL_VERSION/;s/(PKG_HASH:=)[^\"]*/\1$OPENSSL_HASH/" package/libs/openssl/Makefile

# nghttp3
rm -rf feeds/packages/libs/nghttp3
git clone https://github.com/sbwml/package_libs_nghttp3 package/libs/nghttp3

# ngtcp2
rm -rf feeds/packages/libs/ngtcp2
git clone https://github.com/sbwml/package_libs_ngtcp2 package/libs/ngtcp2

# curl - fix passwall `time_pretransfer` check
rm -rf feeds/packages/net/curl
git clone https://github.com/sbwml/feeds_packages_net_curl feeds/packages/net/curl

#golang 24.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang


patch -p1 < 100-openwrt-firewall4-add-custom-nft-command-support.patch
patch -p1 < 0010-kernel-update-TCP-BBR-to-v3.patch
patch -p1 < 0011-iproute2-ss-output-TCP-BBRv3-diag-information.patch
patch -p1 < 0015-iproute2-build-quirk.patch


./scripts/feeds update -a
./scripts/feeds install -a


# 删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
rm -f package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
if [ $? -eq 0 ]; then
  echo "已删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p"
else
  echo "错误：删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p 失败"
fi

# 创建 MT7981 固件符号链接
EEPROM_FILE="package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/MT7981_iPAiLNA_EEPROM.bin"
if [ -f "$EEPROM_FILE" ]; then
  mkdir -p files/lib/firmware
  ln -sf /lib/firmware/MT7981_iPAiLNA_EEPROM.bin files/lib/firmware/e2p
  echo "符号链接已创建"
  ls -l files/lib/firmware/e2p || { echo "错误：符号链接创建失败"; exit 1; }
else
  echo "错误：$EEPROM_FILE 不存在，无法创建符号链接"
  exit 1
fi

sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

sudo rm -rf package/base-files/files/etc/banner

sed -i "s/%D %V %C/%D %V $(TZ=UTC-8 date +%Y.%m.%d)/" package/base-files/files/etc/openwrt_release

sed -i "s/%R/by $OP_author/" package/base-files/files/etc/openwrt_release

date=$(date +"%Y-%m-%d")
echo "                                                    " >> package/base-files/files/etc/banner
echo ".___                               __         .__" >> package/base-files/files/etc/banner
echo "|   | _____   _____   ____________/  |______  |  |" >> package/base-files/files/etc/banner
echo "|   |/     \ /     \ /  _ \_  __ \   __\__  \ |  |" >> package/base-files/files/etc/banner
echo "|   |  Y Y  \  Y Y  (  <_> )  | \/|  |  / __ \|  |__" >> package/base-files/files/etc/banner
echo "|___|__|_|  /__|_|  /\____/|__|   |__| (____  /____/" >> package/base-files/files/etc/banner
echo "          \/      \/                        \/      " >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner
echo "         %D ${date} by $OP_author                     " >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner
echo "                                                      " >> package/base-files/files/etc/banner
