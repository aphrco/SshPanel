#!/bin/bash
version="1.0"
date="2023-10-16"
title="SSH Panel Iranvpn24 v$version"


USER_FILEALL="/root/sshuser/userall.txt"
USER_FILE="/root/sshuser/users.txt"
SETTING_FILE="/root/sshuser/setting.txt"
DEFAULT_CREATED_DATE="2023-01-01"
SSHD_CONFIG="/etc/ssh/sshd_config"

read_setting() {
    if [ -f "$SETTING_FILE" ]; then
        DEFAULT_USERNAME_SUFFIX=$(cat "$SETTING_FILE")
    else
        DEFAULT_USERNAME_SUFFIX="iranvpn24-"  
    fi
}


generate_credentials() {
    username="$DEFAULT_USERNAME_SUFFIX$((RANDOM % 100))"
    password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6 ; echo '')
}


add_user() {
    clear

    random_number=$((1 + RANDOM % 9999))
	password=$(shuf -i 100000-999999 -n 1) 

    echo "Enter your Telegram username:"
    read telegramuser

    echo "Enter the expiration days for the user:"
    read expiration_days

    created_date=$(date '+%Y-%m-%d')
    expiration_date=$(date -d "$created_date + $expiration_days days" '+%Y-%m-%d')
    
    read_setting  
    username="$DEFAULT_USERNAME_SUFFIX$random_number"  

    useradd $username -m -d /home/$username -s /bin/false

    echo "$username:$password" | chpasswd

    echo "$username:$password:$telegramuser:$created_date:$expiration_date" >> $USER_FILE

    echo "$username:$password:$telegramuser:$created_date:$expiration_date" >> $USER_FILEALL

   sudo usermod -e $expiration_date $username
    host=$(grep "^host:" "$SETTING_FILE" | awk '{print $2}')
    port=$(grep "^port:" "$SETTING_FILE" | awk '{print $2}')
    port_udpqw=$(grep "^port_udpqw:" "$SETTING_FILE" | awk '{print $2}')

    echo "Add New User Success:"
    echo "Telegram User: $telegramuser"
    echo "Username: $username"
    echo "Password: $password"
    echo "Host: $host"
    echo "Port: $port"
    echo "Port UDPQW: $port_udpqw"
    echo "Expiration Date: $expiration_date"
    echo "Maximum Device : 3 mac ip"
    echo ""
    echo " -----------------------------"
    read -p "Press Enter to continue..."
    user_menu


}


#delete manual user
delete_user() {
    clear
    echo "User List:"
    awk -F":" '!/^#/ {print NR ". " $1}' $USER_FILE
    read -p "Select User Account for Deletion: " user_number
    if [[ "$user_number" =~ ^[0-9]+$ ]]; then
        username=$(awk -F":" -v n=$user_number '!/^#/ && NR==n {print $1}' $USER_FILE)
        if [ -n "$username" ]; then
            clear
            userdel -r $username
            echo "User $username deleted successfully"

            sed -i "/^$username:/d" $USER_FILE

            echo "$username:$(date '+%Y-%m-%d %H:%M:%S')" >> deleted_accounts.txt
        else
            echo "Invalid User."
        fi
    else
        echo "Invalid input. Please enter a valid number."
    fi
}


# delete expaire user

delete_expired_users() {
clear
    current_date=$(date '+%Y-%m-%d')
    while IFS=: read -r username _ _ _ expiration_date; do
			          
		if [[ "$(date -d "$expiration_date" +%s)" -le "$(date +%s)" ]]; then
			
		    sudo userdel -r $username
            sed -i "/^$username:/d" $USER_FILE
            echo "$username:$(date '+%Y-%m-%d %H:%M:%S')" >> deleted_accounts.txt
            echo "User $username deleted due to expiration."
			echo "---------------------------------"
        fi
    done < $USER_FILE
	echo "expair account success "
}


#change password
change_user_password() {
    clear
    echo "User List:"
    grep -v "^#" $USER_FILE | awk -F":" '{print NR ". " $1}'
    read -p "Select User Account to Change Password: " user_number
    username=$(grep -v "^#" $USER_FILE | awk -F":" -v n=$user_number 'NR==n {print $1}')
    if [ -n "$username" ]; then
        read -p "Enter New Password for $username: " new_password
        awk -v user="$username" -v new_pass="$new_password" -F":" '$1 == user { $2 = new_pass }1' OFS=":" $USER_FILE > temp_users.txt
        mv temp_users.txt $USER_FILE
        echo "Password for user $username changed successfully."
        #sho menu user 
    echo ""
    echo " -----------------------------"
    read -p "Press Enter to continue..."
    user_menu

    else
        echo "Invalid User."
    fi
}


#change expair date
extend_user_expiration() {
    clear
    echo "Select a user to extend their expiration date:"
    awk -F":" '!/^#/ {print NR ". " $1}' $USER_FILE
    read -p "Select User: " user_number
    
    selected_user=$(awk -F":" -v n=$user_number '!/^#/ && NR==n {print $1}' $USER_FILE)
    
    if [ -n "$selected_user" ]; then
        echo "Current Expiration Date for $selected_user:"
        grep "^$selected_user:" $USER_FILE | awk -F":" '{print $5}'
        
        echo "Enter the number of days to extend the expiration date:"
        read extension_days
        current_line=$(grep "^$selected_user:" $USER_FILE)
        current_password=$(echo "$current_line" | awk -F":" '{print $2}')
        current_telegramuser=$(echo "$current_line" | awk -F":" '{print $3}')
        current_created_date=$(echo "$current_line" | awk -F":" '{print $4}')
        current_expiration_date=$(grep "^$selected_user:" $USER_FILE | awk -F":" '{print $5}')
        new_expiration_date=$(date -d "$current_expiration_date + $extension_days days" '+%Y-%m-%d')
        
       sed -i "s/^$selected_user:.*$/$selected_user:$current_password:$current_telegramuser:$current_created_date:$new_expiration_date/" $USER_FILE

        
        sudo chage -E  $new_expiration_date $selected_user
        echo "Expiration date for $selected_user extended to: $new_expiration_date"
        
        #sho menu user 
        echo ""
        echo " -----------------------------"
        read -p "Press Enter to continue..."
        user_menu
    else
        echo "Invalid User."
        
            #sho menu user 
        echo ""
        echo " -----------------------------"
        read -p "Press Enter to continue..."
        user_menu
    fi
}

#setting 
#change suffic name 
change_username_suffix() {
    clear
    echo "Enter the default username suffix: "
    read default_suffix
    echo "$default_suffix" > "$SETTING_FILE"
    echo "Default username suffix set to: $default_suffix"
    read -p "Press Enter to continue..."
}



#change port 
change_ssh_port() {
    echo "Enter the new SSH port:"
    read new_port
    sed -i "s/Port .*/Port $new_port/" "$SSHD_CONFIG"
    systemctl restart sshd
    echo "SSH port changed to: $new_port"
    }



#report
#show all user
show_user_all() {
    clear
    printf "%-20s %-20s %-20s %-28s %-28s\n" "Username" "Password" "Telegram User" "Create Date" "Expiration Date"
    echo "===================================================================="
    while IFS=: read -r username password telegramuser created_date expiration_date; do
        if [ "$created_date" != "$DEFAULT_CREATED_DATE" ]; then
            printf "%-20s %-20s %-20s %-28s %-28s\n" "$username" "$password" "$telegramuser" "$created_date" "$expiration_date"
        fi
    done < $USER_FILEALL
#sho menu user 
    echo ""
    echo " -----------------------------"
    read -p "Press Enter to continue..."
    show_report_menu
    
}

#show active user
show_user_count() {
    clear
    echo "ALL USER ARSHIVE:"
    printf "%-20s %-20s %-20s %-28s %-28s\n" "Username" "Password" "Telegram User" "Create Date" "Expiration Date"
    echo "===================================================================="
    while IFS=: read -r username password telegramuser created_date expiration_date; do
        if [ "$created_date" != "$DEFAULT_CREATED_DATE" ]; then
            printf "%-20s %-20s %-20s %-28s %-28s\n" "$username" "$password" "$telegramuser" "$created_date" "$expiration_date"
        fi
    done < $USER_FILE
    echo "--------------------------------------------------------------------"
    #sho menu user 
    echo ""
    echo " -----------------------------"
    read -p "Press Enter to continue..."
    user_menu

}



#last 20 accunt
show_last_deleted_users() {
    clear
    echo "Last 20 Deleted Users:"
    tail -n 20 deleted_accounts.txt | awk -F":" '{print $1, "Deleted at", $2}'
}

#show connect device
connect_to_network() {
    clear
    echo "Select a user to view their network connections:"
    awk -F":" '!/^#/ {print NR ". " $1}' $USER_FILE
    read -p "Select User: " user_number
    
    selected_user=$(awk -F":" -v n=$user_number '!/^#/ && NR==n {print $1}' $USER_FILE)
    
    if [ -n "$selected_user" ]; then
        clear
        echo "Network connections for user: $selected_user"
        echo "--------------------------------------"
        netstat -et --numeric-ports --numeric-hosts 2>/dev/null | grep "$selected_user"
    else
        echo "Invalid User."
    fi
    
   #sho REPORT user 
    echo ""
    echo " -----------------------------"
    read -p "Press Enter to continue..."
    show_report_menu



}



show_ssh_connection_stats() {
    clear

    # Read user list from users.txt into an array
    users=()
    while IFS= read -r line; do
        users+=("$line")
    done < "$USER_FILE"

    # Display the list of users with numeric indexes
    echo "User List:"
    for ((i = 0; i < ${#users[@]}; i++)); do
        echo "$(($i + 1)): $(echo "${users[$i]}" | awk -F':' '{print $1}')"
    done

    # Prompt for user selection
    read -p "Enter the number of the user to check SSH connections: " selection

    # Check if the selection is a valid number
    if [[ $selection =~ ^[0-9]+$ && $selection -ge 1 && $selection -le ${#users[@]} ]]; then
        # Extract the username for the selected user
        selected_user=$(echo "${users[$(($selection - 1))]}" | awk -F':' '{print $1}')

        # Extract and display SSH connection stats for the selected user
        echo "SSH Connection Stats for $selected_user:"
        echo "Count    Address    Login Time"
        grep "Accepted" /var/log/auth.log* | grep "sshd" | grep "$selected_user" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr 
    else
        echo "Invalid selection."
    fi

    echo " -----------------------------"
    read -p "Press Enter to continue..."
    show_report_menu
}








abute_me(){
clear
 figlet "SSH Tunnel" | lolcat -a -s 100000
    echo "Develop : Alibakhtiari - Vev :1.2 "
    echo "github : https://github.com/aphrco  "
    echo "instagram : Ali.bakhtiarib"  
  echo "------------------------------------------"
}







#Menu
show_menu() {
    clear    
    figlet "SSH Tunnel" | lolcat -a -s 100000
    echo "IRVPS.shop -  SSH Service Menu"
    echo "------------------------------------------"
    echo "1. User Account manager"
    echo "2. Report User Account"
    echo "3. Settings"
    echo "4. Abute us"
    echo "5.Exit"
    read -p "Please Select an Option: " option
    case $option in
        1) user_menu ;;
        2) show_report_menu ;;
        3) show_settings_menu ;;
	4) abute_me ;;
	5) exit ;;
        *) echo "Please Select an Option: " ;;
    esac
}



#show user menu 
user_menu() {
    clear
    figlet "User Manager - SSh Tunnel" | lolcat -a -s 100000
    echo "IRVPS.shop -  SSH Service Menu"
    echo "----------------------------------------"
    echo "1. Add User Account"
    echo "2. Delete User Account"
    echo "3. Show Users "
    echo "4. Change Password User"
    echo "5. Change expired time"
    echo "6. Back menu"
read -p "Please Select an Option: " option
case $option in
    1) add_user ;;
    2) delete_user ;;
    3) show_user_count ;;
    4) change_user_password ;;
    5) extend_user_expiration ;;
    6) show_menu ;;
esac
}



#menu report
show_report_menu() {
    clear
    figlet "User Manager - SSh Tunnel" | lolcat -a -s 100000
    echo "IRVPS.shop -  SSH Service Menu"
    echo "report Menu"
    echo "----------------------------------"
    echo "1. Show Users "
    echo "2. Show Last 20 Deleted Users"
    echo "3. Show Arshive Users "
    echo "4. Ip Connect Count"
    echo "5. log User Avtive"
    echo "6. Back to Main Menu"
    read -p "Please Select an Option: " settings_option
    case $settings_option in
        1) show_user_count;;
        2) show_last_deleted_users ;;
        3) show_user_all ;;
        4) show_ssh_connection_stats ;;
        5) connect_to_network ;;
	6) show_menu ;;
        *) echo "Please Select an Option: " ;;
    esac
}


#menu setting
show_settings_menu() {
    clear
    figlet "Settings Menu - SSh Tunnel" | lolcat -a -s 100000
    echo "IRVPS.shop -  SSH Service Menu"
    echo "----------------------------------"
    echo "1. Change Username Suffix"
    echo "2. Add SSH Port"
    echo "3. Delete user expair (Cron job 12pm) "
    echo "4. Back to Main Menu" 
    read -p "Please Select an Option: " settings_option
    case $settings_option in
        1) change_username_suffix ;; 
        2) change_ssh_port ;;  
        3) delete_expired_users ;;
        4) show_menu ;;
        *) echo "Please Select an Option: " ;;
    esac
}



if [ "$1" = "delete_expired_users" ]; then
    delete_expired_users
	
else 
show_menu
fi
