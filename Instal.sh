SETTING_FILE="setting.txt"
SSHD_CONFIG="/etc/ssh/sshd_config"
sudo apt update
sudo apt upgrade
sudo apt install figlet
sudo apt install nethogs
wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && bash bbr.sh
sudo apt intall speedtest-cli
mkdir sshpanel
cd sshpanel


clear
echo "Welcome to the installation process!"
echo "Enter the host address(IP /Domain): "
read host

# Save host in the setting file
echo "host: $host" > "$SETTING_FILE"

# Enter the new SSH port
echo "Enter the new SSH port(Defult: 22):"
read new_port
# Update SSH port in the SSH daemon config file
# Comment the existing "Port" line and add new "Port" lines
sudo sed -i -e "s/^Port /#Port /" "$SSHD_CONFIG"
sudo sh -c "echo  'Port 22\nPort $new_port' >> $SSHD_CONFIG"
sudo systemctl restart sshd
echo "SSH ports changed to: 22 and $new_port"
# Save the new port in the setting file
echo "port: $new_port" >> "$SETTING_FILE"
cp   badvpn-udpgw64 /usr/bin/badvpn-udpgw 
echo "#!/bin/sh -e 
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:10731
exit 0" > "/etc/rc.local"
chmod +x /etc/rc.local && chmod +x /usr/bin/badvpn-udpgw && systemctl daemon-reload && sleep 0.5 && systemctl start rc-local.service && screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:10731
cron ="1 0 * * *  $(pwd)/sshadd.sh delete_expired_users >/dev/null 2>&1"
print "$cron"
echo "install Success"