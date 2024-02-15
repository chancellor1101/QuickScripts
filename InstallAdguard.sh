if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
docker run --name adguardhome\
    --restart unless-stopped\
    -v /var/teammts/adguard/work:/opt/adguardhome/work\
    -v /var/teammts/adguard/config:/opt/adguardhome/conf\
    -p 53:53/tcp -p 53:53/udp\
    -p 67:67/udp -p 68:68/udp\
    -p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp\
    -p 853:853/tcp\
    -p 853:853/udp\
    -p 5443:5443/tcp -p 5443:5443/udp\
    -p 6060:6060/tcp\
    -d adguard/adguardhome