#!/bin/bash
echo -e  "\033c \033[1;31m\n \e[1m ahmetozer.org \033[1;33mOpenVPN \033[1;37mInstall helper \n  https://ahmetozer.org/products.html"

var1="$1"
var2="$2"
var3="$3"
var4="$4"


if [ "$EUID" -ne 0 ]
  then echo "Please this app run as root. 'sudo $0'"
  exit
fi

function keyservice() {
  if screen -list | grep -q "OpenVPNKeyservice"; then
    echo "The key service is already running. To turn it off, use the $0 keystop or visit install.ahmetozer.org/vpn"
  else
    screen -S OpenVPNKeyservice -d -m node /etc/openvpn/keyserver.js
    echo "Key service started"
  fi
}
function keystop() {
  if screen -list | grep -q "OpenVPNKeyservice"; then
    screen -X -S OpenVPNKeyservice quit
    echo "Key service stopped"
  else
    echo "The key service is not running. To turn it on, use the $0 keyservice"
  fi
}
function key() {
  if [ -f "/etc/openvpn/install.ahmetozer.org.key" ];then
    echo "Your Key is:"
    cat /etc/openvpn/install.ahmetozer.org.key
    echo
  else
    echo "The VPN server is not installed or key file not found."
  fi
}

function install() {
  if [ "$var1" == "fast-install" ]; then
    echo "fast install mode $var1 $0"
  else
    while true; do
        read -p "Do you want to install this software? (Y/N) > " yn
        case $yn in
            [Yy]* ) echo "installing..." ; break;;
            [Nn]* ) echo "Setup aborted" ; exit;;
            * ) echo "If Yes please indicate Y, if no please indicate N.";;
        esac
    done
  fi
  echo
  echo
  echo 'Controlling operating system.'
  source /etc/lsb-release
  if [ $DISTRIB_ID == 'Ubuntu' ];then
    if [ $DISTRIB_RELEASE == '18.04' ]; then
      echo 'Your operating system is supported.'
    else
      echo 'You are using a different version of Ubuntu 18.04. You may experience problems in use.'
    fi
  else
    echo 'Your operating system is not supported.'; exit
  fi

  echo 'Checking the dns server.'
  nslookup google.com 2>&1 > /dev/null
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo 'DNS query successfully completed.'
  else
    echo 'There is a problem with the DNS server settings.'; exit
  fi

  myipadress=`wget -4qO- 'http://whatismyip.akamai.com/' 2>&1`
  if [ -v myipadress ]; then
    echo "Your ip address $myipadress";
  else
    echo "Your ip address could not be determined."; exit
  fi
  echo
  echo
    #fast-install start
  if [ "$var1" == "fast-install" ]; then
    case $var2 in
        [TCPtcp]* ) porttype='tcp'; echo "$porttype Selected";;
        [UDPudp]* ) porttype='udp'; echo "$porttype Selected";;
        * ) echo "Please type 'tcp' or 'udp'. Fast install data is corrupted"; exit ;;
    esac
    portnumber=$var3
    if ! [[ "$portnumber" =~ ^[0-9]+$ ]]; then
          echo "Only Number accepted. Fast install data is corrupted"; exit
        else
          if [ "$portnumber" -ge 1 -a "$portnumber" -le 65535 ];then
            if [ "$porttype" == "tcp" ]; then
              if (lsof -i :$portnumber | grep TCP);then
                echo "Port already usage. Please select another port."; exit
              else
                echo "Selected port $portnumber/tcp"
              fi
            fi

            if [ "$porttype" == "udp" ]; then
              if (lsof -i :$portnumber | grep UDP);then
                echo "Port already usage. Please select another port."; exit
              else
                echo "Selected port $portnumber/udp"
              fi
            fi
          else
            echo "Please select a number between 1 and 65535 for the port. Fast install data is corrupted"; exit
        fi
    fi
    case $var4 in
        [TUNtun]* ) devicetype='tun'; echo "$devicetype Selected";;
        [TAPtap]* ) devicetype='tap'; echo "$devicetype Selected";;
        * ) echo "Please write 'tun' or 'tap'.";;
    esac
    #fast-install end
  else
    #read by terminal
    while true; do
      echo "UDP can have a faster and lower latency connection, but some companies block UDP."
      read -p "What protocol do you want to use for VPN? (TCP/UDP) > " ptype
      case $ptype in
          [TCPtcp]* ) porttype='tcp'; echo "$porttype Selected"; break;;
          [UDPudp]* ) porttype='udp'; echo "$porttype Selected"; break;;
          * ) echo "Please type 'tcp' or 'udp'.";;
      esac
    done
    echo
    echo
    while true; do
      read -p "What port number do you want to use for VPN? (suggested 443) > " portnumber
      if ! [[ "$portnumber" =~ ^[0-9]+$ ]]; then
            echo "Only Number accepted."
          else
            if [ "$portnumber" -ge 1 -a "$portnumber" -le 65535 ];then
              if [ "$porttype" == "tcp" ]; then
                if (lsof -i :$portnumber| grep TCP);then
                  echo "Port already usage. Please select another port."
                else
                  echo "Selected port $portnumber/tcp"
                  break
                fi
              fi

              if [ "$porttype" == "udp" ]; then
                if (lsof -i :$portnumber | grep UDP);then
                  echo "Port already usage. Please select another port."
                else
                  echo "Selected port $portnumber/udp"
                  break
                fi
              fi
            else
              echo "Please select a number between 1 and 65535 for the port."
          fi
      fi
    done
    echo
    echo
    while true; do
      echo "If you only use the VPN on the computer, select TAP"
      echo "If you are going to use your VPN phone, select tun as the device type. Mobile devices only support tun devices, while computers support both tum and tap."
      read -p "What type of device do you want to use for VPN? (TUN/TAP) > " dtype
      case $dtype in
          [TUNtun]* ) devicetype='tun'; echo "$devicetype Selected"; break;;
          [TAPtap]* ) devicetype='tap'; echo "$devicetype Selected"; break;;
          * ) echo "Please write 'tun' or 'tap'.";;
      esac
    done
    #read by terminal end
  fi

  echo "Updating package lists"
  apt-get update
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo 'The package list update has been successfully completed.'
  else
    echo 'There is a problem with updating package list.'; exit
  fi

  echo "Instaling programs"
  apt-get install openvpn easy-rsa wget openssl nodejs npm screen ubuntu-server ca-certificates -y
  currentdir=`pwd`
  cd /etc/openvpn
  npm install crypto-js
  cd $currentdir
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo 'Installation of the programs is complete'
  else
    echo 'The programs could not be installed.'; exit
  fi

  cp -r /usr/share/easy-rsa/ /etc/openvpn
  mkdir -p /etc/openvpn/easy-rsa/keys
  cd /etc/openvpn/easy-rsa/


echo -e '# easy-rsa parameter settings\nexport EASY_RSA="/etc/openvpn/easy-rsa/" \nexport OPENSSL="openssl" \nexport PKCS11TOOL="pkcs11-tool"\nexport GREP="grep"\nexport KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`\nexport KEY_DIR="$EASY_RSA/keys"\nexport PKCS11_MODULE_PATH="dummy"\nexport PKCS11_PIN="dummy"\nexport KEY_SIZE=2048\nexport CA_EXPIRE=3650\nexport KEY_EXPIRE=3650\nexport KEY_COUNTRY="US"\nexport KEY_PROVINCE="CA"\nexport KEY_CITY="SanFrancisco"\nexport KEY_ORG="Fort-Funston"\nexport KEY_EMAIL="me@myhost.mydomain"\nexport KEY_OU="MyOrganizationalUnit"\nexport KEY_NAME="server"' > /etc/openvpn/easy-rsa/vars
  #export varibles
  export EASY_RSA="/etc/openvpn/easy-rsa"
  export OPENSSL="openssl"
  export PKCS11TOOL="pkcs11-tool"
  export GREP="grep"
  export KEY_CONFIG="/etc/openvpn/easy-rsa/openssl-1.0.0.cnf"
  export KEY_DIR="/etc/openvpn/easy-rsa/keys"
  export PKCS11_MODULE_PATH="dummy"
  export PKCS11_PIN="dummy"
  export KEY_SIZE="2048"
  export CA_EXPIRE="3650"
  export KEY_EXPIRE="3650"
  export KEY_COUNTRY="US"
  export KEY_PROVINCE="CA"
  export KEY_CITY="SanFrancisco"
  export KEY_ORG="Fort-Funston"
  export KEY_EMAIL="me@myhost.mydomain"
  export KEY_OU="MyOrganizationalUnit"
  export KEY_NAME="server"
  #

  cat /etc/openvpn/easy-rsa/vars                                                #Değişkenleri gör
  mv /etc/openvpn/dh2048.pem /etc/openvpn/dh2048.pem.old                        #dhparam eskisini yedekle
  openssl dhparam -dsaparam -out /etc/openvpn/dh2048.pem 2048                   #yeni dhparam oluştur
  /etc/openvpn/easy-rsa/clean-all                                               #klasörü temzile
  /etc/openvpn/easy-rsa/build-ca --batch                                        #ca sertifikasını oluştur
  /etc/openvpn/easy-rsa/build-key --server --batch server                       #Sunucu dosyasını oluştur
  cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn                         #Dosyayı kopyala
  cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn                         #Dosyayı kopyala
  cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn                             #Dosyayı kopyala
  /etc/openvpn/easy-rsa/build-key --batch client1                               #istemci dosyasını oluştur

  echo  "######
# https://install.ahmetozer.org/vpn/
# Server Setting File
# software writed by https://ahmetozer.org
######
port $portnumber
proto $porttype
dev $devicetype
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 10.8.0.0 255.255.255.0
push 'redirect-gateway def1 bypass-dhcp'
push 'dhcp-option DNS 1.1.1.1'
push 'dhcp-option DNS 208.67.220.220'
duplicate-cn
max-clients 100
keepalive 1 5
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
user nobody
group nogroup
script-security 3
up /etc/openvpn/fwall" > /etc/openvpn/server.conf

  if [ $porttype == 'udp' ]; then
    echo 'sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"' >> /etc/openvpn/server.conf
  fi

  echo "#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
ufw allow $portnumber/$porttype
ufw allow 8443/tcp
iptables -I FORWARD -s 10.8.0.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -I POSTROUTING   -s 10.8.0.0/24 -j MASQUERADE
exit 0" > /etc/openvpn/fwall
  chmod 755 /etc/openvpn/fwall

  echo "######
# https://install.ahmetozer.org/vpn/
# Server Setting File
# software writed by https://ahmetozer.org
######
client
dev $devicetype
proto $porttype
remote $myipadress $portnumber
resolv-retry infinite
nobind
fast-io
persist-key
persist-tun
cipher AES-256-CBC
verb 0
######
# Sertifikalar
######
"> /etc/openvpn/install.ahmetozer.org.ovpn
    echo '<ca>' >> /etc/openvpn/install.ahmetozer.org.ovpn
    cat /etc/openvpn/ca.crt >> /etc/openvpn/install.ahmetozer.org.ovpn
    echo '</ca>
<cert>' >> /etc/openvpn/install.ahmetozer.org.ovpn
    cat /etc/openvpn/easy-rsa/keys/client1.crt >> /etc/openvpn/install.ahmetozer.org.ovpn
    echo '</cert>
<key>' >> /etc/openvpn/install.ahmetozer.org.ovpn
    cat /etc/openvpn/easy-rsa/keys/client1.key >> /etc/openvpn/install.ahmetozer.org.ovpn
    echo '</key>' >> /etc/openvpn/install.ahmetozer.org.ovpn

cat >/etc/openvpn/keyserver.js <<EOF
    'use strict';
    var http = require('http');
    var fs = require('fs');
    const https = require('https');

    var CryptoJS = require('crypto-js');
    var key = 'pass phrase';
    var encrypted
    var ecr = function(obj)
    {
        encrypted = CryptoJS.AES.encrypt(obj, key).toString();
        var hmac = CryptoJS.HmacSHA256(encrypted, CryptoJS.SHA256(key)).toString();
        return hmac + encrypted;
    };

    var dcr = function(obj)
    {
        return CryptoJS.AES.decrypt(obj, key).toString(CryptoJS.enc.Utf8);
    };

    var webout
    var shutdown
    fs.readFile('/etc/openvpn/install.ahmetozer.org.key', function(err, data) {
      key = data.toString()
      console.log(key);
    });
    fs.readFile('/etc/openvpn/install.ahmetozer.org.ovpn', function(err, data) {
      var obj = data.toString()
      encrypted = CryptoJS.AES.encrypt(obj, key).toString();
      var hmac = CryptoJS.HmacSHA256(encrypted, CryptoJS.SHA256(key)).toString();
      webout =  hmac + encrypted;
      shutdown = CryptoJS.HmacSHA256(encrypted, CryptoJS.SHA256(key+"shutdown")).toString();
      console.log("shutdown url "+shutdown);
    });

    http.createServer(function (req, res) {
      if (req.url == '/ovpn') {
        //res.write(shutdown);
        res.write(webout);
        res.end();
        return;
      }
      if (req.url == '/ovpn/'+shutdown) {
        res.write("Key server closed");
        res.end();
        process.exit()
      }
      res.write("<h1><a src='https://ahmetozer.org'>https://ahmetozer.org<a></h1><h2>OpenVPN service https://install.ahmetozer.org/vpn</h2>");
      res.end();
    }).listen(8443);
EOF

	  service openvpn@server restart
    parola=`< /dev/urandom tr -dc a-z | head -c${1:-11}`
    printf "$parola" > /etc/openvpn/install.ahmetozer.org.key
    keyservice
    echo "OpenVPN installed"
    echo "visit https://install.ahmetozer.org/vpn/?ip=$myipadress"
	echo "Your ip address:"
    echo "$myipadress"
    echo "Your password:"
    echo "$parola"
    echo
}



function uninstall() {
  while true; do
      read -p "Do you want to uninstall the VPN? (Y/N) > " yn
      case $yn in
          [Yy]* ) echo "uninstalling..." ; break;;
          [Nn]* ) echo "Aborting uninstall." ; exit;;
          * ) echo "If Yes please indicate Y, if no please indicate N.";;
      esac
  done
  keystop
  apt autoremove --purge openvpn -y
  rm -rf /etc/openvpn
  echo "Uninstall successfully completed."
}



  case "$var1" in
        install)
          if [ -f "/etc/openvpn/install.ahmetozer.org.ovpn" ];then
            echo "VPN already installed"
          else
          	echo "The VPN server is not installed. Installing the VPN server"
            install;
          fi
            ;;

        uninstall)
          if [ -f "/etc/openvpn/install.ahmetozer.org.ovpn" ];then
            uninstall
          else
            echo "The VPN server is not installed."
            exit
          fi
            ;;

        status)
            service openvpn@server status
            ;;
        keyservice)
            keyservice
            ;;
        keystop)
            keystop
            ;;
        key)
            key
            ;;
        fast-install)
            install
            ;;
        *)
			     	echo $"Use one of the '$0 {install|uninstall|status|keyservice|keystop|key} commands to use'"
            exit 1
          esac
