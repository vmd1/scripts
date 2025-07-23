#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for input with a default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    read -p "$prompt [$default]: " input
    eval "$var_name=\${input:-$default}"
}

# Function to prompt for yes/no input
prompt_yes_no() {
    local prompt="$1"
    local var_name="$2"
    
    while true; do
        read -p "$prompt (y/n): " yn
        case $yn in
            [Yy]* ) eval "$var_name=true"; break;;
            [Nn]* ) eval "$var_name=false"; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to add entry to hosts file
add_host_entry() {
    local ip="$1"
    local hostname="$2"
    local hosts_file="/etc/hosts"
    local template_file="/etc/cloud/templates/hosts.debian.tmpl"
    
    # Check if /etc/hosts has a comment about template location
    if grep -q "hosts.debian.tmpl" "$hosts_file"; then
        hosts_file="$template_file"
        echo "Using template file at $hosts_file"
    fi
    
    # Check if entry already exists
    if ! grep -q "$hostname" "$hosts_file"; then
        echo "$ip    $hostname" | sudo tee -a "$hosts_file"
    else
        echo "Entry for $hostname already exists in $hosts_file"
    fi
}

# Function to prompt for credentials
prompt_credentials() {
    local prompt="$1"
    local var_name="$2"
    local password_var_name="$3"
    
    read -p "$prompt username: " username
    read -s -p "$prompt password: " password
    echo  # New line after password input
    
    eval "$var_name=\$username"
    eval "$password_var_name=\$password"
}

# Function to setup gluster mount
setup_gluster_mount() {
    local master_server="$1"
    local mount_point="/ultmt"
    
    # Create mount point if it doesn't exist
    sudo mkdir -p "$mount_point"
    
    # Create systemd mount unit
    cat << EOF | sudo tee /etc/systemd/system/ultmt.mount
[Unit]
Description=Gluster Volume Mount
After=network.target

[Mount]
What=${master_server}:/gvl0
Where=${mount_point}
Type=glusterfs
Options=_netdev

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ultmt.mount
    sudo systemctl start ultmt.mount
}

# Function to setup SMB mount
setup_smb_mount() {
    local master_server="$1"
    local mount_point="/ultmt"
    local username="$2"
    local password="$3"
    
    # Create mount point if it doesn't exist
    sudo mkdir -p "$mount_point"
    
    # Create systemd mount unit
    cat << EOF | sudo tee /etc/systemd/system/ultmt.mount
[Unit]
Description=SMB Share Mount
After=network.target

[Mount]
What=//${master_server}/Server\ Files
Where=${mount_point}
Type=cifs
Options=_netdev,credentials=/etc/smbcredentials,uid=$(id -u),gid=$(id -g),file_mode=0755,dir_mode=0755

[Install]
WantedBy=multi-user.target
EOF

    # Create credentials file
    echo "username=$username" | sudo tee /etc/smbcredentials
    echo "password=$password" | sudo tee -a /etc/smbcredentials
    sudo chmod 600 /etc/smbcredentials

    sudo systemctl daemon-reload
    sudo systemctl enable ultmt.mount
    sudo systemctl start ultmt.mount
}

# Function to setup SSSD
setup_sssd() {
    local username="$1"
    local password="$2"
    local domain="$3"
    local ldap_base="$4"
    
    # Install required packages
    sudo apt update
    sudo apt install -y sssd sssd-tools libnss-sss libpam-sss libsss-sudo

    # Create SSSD config
    cat << EOF | sudo tee /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
domains = ${domain}

[nss]

[pam]

[domain/${domain}]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_schema = rfc2307
ldap_uri = ldaps://lldap.${domain}:6360/
ldap_search_base = ${ldap_base}

# Bind credentials
ldap_default_bind_dn = uid=${username},ou=people,${ldap_base}
ldap_default_authtok = ${password}

# TLS settings
ldap_tls_reqcert = demand
ldap_tls_cacert = /ultmt/cert.pem

# User mappings
ldap_user_search_base = ou=people,${ldap_base}
ldap_user_object_class = posixAccount
ldap_user_name = uid
ldap_user_gecos = uid
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_user_home_directory = homeDirectory
ldap_user_shell = unixShell
ldap_user_ssh_public_key = sshPublicKey

# Group mappings
ldap_group_search_base = ou=groups,${ldap_base}
ldap_group_object_class = groupOfUniqueNames
ldap_group_name = cn
ldap_group_member = uniqueMember

access_provider = permit
cache_credentials = true
EOF

    sudo chmod 600 /etc/sssd/sssd.conf
    sudo systemctl restart sssd
}

# Function to setup SSH public key sync
setup_ssh_keysync() {
    # Backup original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Add required lines if they don't exist
    if ! grep -q "AuthorizedKeysCommand" /etc/ssh/sshd_config; then
        echo "AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys" | sudo tee -a /etc/ssh/sshd_config
        echo "AuthorizedKeysCommandUser nobody" | sudo tee -a /etc/ssh/sshd_config
    fi

    sudo systemctl restart ssh
    sudo systemctl restart sssd
}

# Function to setup hosts file
setup_hosts_file() {
    # Add all required host entries
    local entries=(
        "192.168.1.101   ultimate.servers.infra.mdi"
        "192.168.1.203   ultimate-rpi3.servers.infra.mdi"
        "192.168.1.103   ultimate-vpc.servers.infra.mdi"
        "100.90.2.104    ultimate-uks-1.servers.infra.mdi"
        "100.90.2.105    ultimate-uks-2.servers.infra.mdi"
    )
    
    local hosts_file="/etc/hosts"
    local template_file="/etc/cloud/templates/hosts.debian.tmpl"
    
    # Check if /etc/hosts has a comment about template location
    if grep -q "hosts.debian.tmpl" "$hosts_file"; then
        hosts_file="$template_file"
        echo "Using template file at $hosts_file"
    fi
    
    # Add each entry if it doesn't exist
    for entry in "${entries[@]}"; do
        local hostname=$(echo "$entry" | awk '{print $2}')
        if ! grep -q "$hostname" "$hosts_file"; then
            echo "$entry" | sudo tee -a "$hosts_file"
            echo "Added entry for $hostname"
        else
            echo "Entry for $hostname already exists in $hosts_file"
        fi
    done
}

# Main script starts here
echo "Starting server provisioning script..."

# Get device hostname
prompt_with_default "Enter device hostname" "$(hostname)" DEVICE_HOSTNAME
sudo hostnamectl set-hostname "$DEVICE_HOSTNAME"

# Get domain information
prompt_with_default "Enter domain (e.g. example.com)" "example.com" DOMAIN_NAME
# Split domain into components for LDAP
DOMAIN_COMPONENTS=$(echo "$DOMAIN_NAME" | sed 's/\./,dc=/g')
LDAP_BASE="dc=${DOMAIN_COMPONENTS}"

# Get master server information
prompt_with_default "Enter master server hostname (or 'n' for individual setup)" "n" MASTER_SERVER
if [ "$MASTER_SERVER" = "n" ]; then
    prompt_with_default "Enter gluster server hostname (or press enter to skip)" "" GLUSTER_SERVER
    prompt_with_default "Enter docker server hostname (or press enter to skip)" "" DOCKER_SERVER
    prompt_with_default "Enter lldap server hostname (or press enter to skip)" "" LLDAP_SERVER
else
    GLUSTER_SERVER="$MASTER_SERVER"
    DOCKER_SERVER="$MASTER_SERVER"
    LLDAP_SERVER="$MASTER_SERVER"
fi

# Get credentials if we're using SMB or LLDAP
if [ "$MASTER_SERVER" != "n" ] || [ -n "$LLDAP_SERVER" ]; then
    prompt_credentials "Enter credentials for SMB/LLDAP" LDAP_USERNAME LDAP_PASSWORD
fi

# Get Tailscale auth key
prompt_with_default "Enter Tailscale auth key" "" TAILSCALE_AUTH_KEY

# Get Docker swarm join token
prompt_with_default "Enter Docker swarm join token (or press enter to skip)" "" DOCKER_SWARM_TOKEN

# Ask about Gluster
prompt_yes_no "Do you want to setup Gluster?" USE_GLUSTER

# Install and configure Tailscale
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --advertise-exit-node --accept-dns=false --advertise-connector --ssh
fi

# Setup mount based on Gluster preference
if [ "$USE_GLUSTER" = true ] && [ -n "$GLUSTER_SERVER" ]; then
    setup_gluster_mount "$GLUSTER_SERVER"
else
    setup_smb_mount "$MASTER_SERVER" "$LDAP_USERNAME" "$LDAP_PASSWORD"
fi

# Configure docker group
sudo groupadd docker -g 722 || true

# Setup SSSD if LLDAP server is provided
if [ -n "$LLDAP_SERVER" ]; then
    setup_sssd "$LDAP_USERNAME" "$LDAP_PASSWORD" "$DOMAIN_NAME" "$LDAP_BASE"
    setup_ssh_keysync
fi

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
rm get-docker.sh

# Join Docker swarm if token provided
if [ -n "$DOCKER_SWARM_TOKEN" ] && [ -n "$DOCKER_SERVER" ]; then
    sudo docker swarm join --token "$DOCKER_SWARM_TOKEN" "$DOCKER_SERVER:2377"
fi

# Install convenience packages
sudo apt update
sudo apt install -y btop figlet

# Add LLDAP entry if server is provided
if [ -n "$LLDAP_SERVER" ]; then
    # Get IP address of LLDAP server
    local lldap_ip
    if [[ "$LLDAP_SERVER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        lldap_ip="$LLDAP_SERVER"
    else
        lldap_ip=$(getent hosts "$LLDAP_SERVER" | awk '{ print $1 }')
    fi
    
    if [ -n "$lldap_ip" ]; then
        if ! grep -q "lldap.${DOMAIN_NAME}" "$hosts_file"; then
            echo "$lldap_ip    lldap.${DOMAIN_NAME}" | sudo tee -a "$hosts_file"
            echo "Added entry for lldap.${DOMAIN_NAME} using IP $lldap_ip"
        else
            echo "Entry for lldap.${DOMAIN_NAME} already exists in $hosts_file"
        fi
    else
        echo "Warning: Could not resolve IP address for LLDAP server $LLDAP_SERVER"
    fi
fi

echo "Provisioning completed successfully!" 