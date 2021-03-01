#!/bin/bash

clear
# Global variables
WIREGUARD_WEBSITE_URL="https://www.wireguard.com"
WIREGUARD_PATH="/etc/wireguard"
WIREGUARD_CLIENT_PATH="$WIREGUARD_PATH/clients"
WIREGUARD_PUB_NIC="wg0"
WIREGUARD_CONFIG="$WIREGUARD_PATH/$WIREGUARD_PUB_NIC.conf"
WIREGUARD_ADD_PEER_CONFIG="$WIREGUARD_PATH/$WIREGUARD_PUB_NIC-add-peer.conf"
WIREGUARD_MANAGER="$WIREGUARD_PATH/wireguard-manager"
WIREGUARD_INTERFACE="$WIREGUARD_PATH/wireguard-interface"
WIREGUARD_PEER="$WIREGUARD_PATH/wireguard-peer"
WIREGUARD_MANAGER_UPDATE="https://raw.githubusercontent.com/clear/wireguard-manager/main/wireguard-manager.sh"
WIREGUARD_CONFIG_BACKUP="/var/backups/wireguard-manager.zip"
WIREGUARD_IP_FORWARDING_CONFIG="/etc/sysctl.d/wireguard.conf"
PIHOLE_ROOT="/etc/pihole"
PIHOLE_MANAGER="$PIHOLE_ROOT/wireguard-manager"
RESOLV_CONFIG="/etc/resolv.conf"
RESOLV_CONFIG_OLD="/etc/resolv.conf.old"
UNBOUND_ROOT="/etc/unbound"
UNBOUND_MANAGER="$UNBOUND_ROOT/wireguard-manager"
UNBOUND_CONFIG="$UNBOUND_ROOT/unbound.conf"
UNBOUND_ROOT_HINTS="$UNBOUND_ROOT/root.hints"
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
UNBOUND_ROOT_SERVER_CONFIG_URL="https://www.internic.net/domain/named.cache"
clear

if [ -x "$(command -v wg)" ]; then
          if [ "$NEW_CLIENT_NAME" == "" ]; then
            echo "Lets name the WireGuard Peer, Use one word only, no special characters. (No Spaces)"
            read -rp "New client peer: " -e NEW_CLIENT_NAME
          fi
          if [ -z "$NEW_CLIENT_NAME" ]; then
            NEW_CLIENT_NAME="$(openssl rand -hex 50)"
          fi
          CLIENT_PRIVKEY=$(wg genkey)
          CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)
          PRESHARED_KEY=$(wg genpsk)
          PEER_PORT=$(shuf -i1024-65535 -n1)
          PRIVATE_SUBNET_V4=$(head -n1 $WIREGUARD_CONFIG | awk '{print $2}')
          PRIVATE_SUBNET_MASK_V4=$(echo "$PRIVATE_SUBNET_V4" | cut -d "/" -f 2)
          PRIVATE_SUBNET_V6=$(head -n1 $WIREGUARD_CONFIG | awk '{print $3}')
          PRIVATE_SUBNET_MASK_V6=$(echo "$PRIVATE_SUBNET_V6" | cut -d "/" -f 2)
          SERVER_HOST=$(head -n1 $WIREGUARD_CONFIG | awk '{print $4}')
          SERVER_PUBKEY=$(head -n1 $WIREGUARD_CONFIG | awk '{print $5}')
          CLIENT_DNS=$(head -n1 $WIREGUARD_CONFIG | awk '{print $6}')
          MTU_CHOICE=$(head -n1 $WIREGUARD_CONFIG | awk '{print $7}')
          NAT_CHOICE=$(head -n1 $WIREGUARD_CONFIG | awk '{print $8}')
          CLIENT_ALLOWED_IP=$(head -n1 $WIREGUARD_CONFIG | awk '{print $9}')
          LASTIPV4=$(grep "/32" $WIREGUARD_CONFIG | tail -n1 | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4)
          LASTIPV6=$(grep "/128" $WIREGUARD_CONFIG | tail -n1 | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4)
          CLIENT_ADDRESS_V4="${PRIVATE_SUBNET_V4::-4}$((LASTIPV4 + 1))"
          CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-4}$((LASTIPV6 + 1))"
          if [ "$LASTIPV4" -ge "255" ]; then
            echo "Error: You have $LASTIPV4 peers the max is 255"
            exit
          fi
          read -p "Berapa hari account [$NEW_CLIENT_NAME] aktif: " AKTIF
          today="$(date +"%Y-%m-%d")"
	expire=$(date -d "$AKTIF days" +"%Y-%m-%d")
          echo "# $NEW_CLIENT_NAME start
[Peer]
PublicKey = $CLIENT_PUBKEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = $CLIENT_ADDRESS_V4/32,$CLIENT_ADDRESS_V6/128
# $NEW_CLIENT_NAME end" >$WIREGUARD_ADD_PEER_CONFIG
          wg addconf $WIREGUARD_PUB_NIC $WIREGUARD_ADD_PEER_CONFIG
          cat $WIREGUARD_ADD_PEER_CONFIG >>$WIREGUARD_CONFIG
          rm -f $WIREGUARD_ADD_PEER_CONFIG
          echo "# $WIREGUARD_WEBSITE_URL
[Interface]
Address = $CLIENT_ADDRESS_V4/$PRIVATE_SUBNET_MASK_V4,$CLIENT_ADDRESS_V6/$PRIVATE_SUBNET_MASK_V6
DNS = $CLIENT_DNS
ListenPort = $PEER_PORT
MTU = $MTU_CHOICE
PrivateKey = $CLIENT_PRIVKEY
[Peer]
AllowedIPs = $CLIENT_ALLOWED_IP
Endpoint = $SERVER_HOST$SERVER_PORT
PersistentKeepalive = $NAT_CHOICE
PresharedKey = $PRESHARED_KEY
PublicKey = $SERVER_PUBKEY" >>$WIREGUARD_CLIENT_PATH/"$NEW_CLIENT_NAME"-$WIREGUARD_PUB_NIC.conf
          echo "Client config --> $WIREGUARD_CLIENT_PATH/$NEW_CLIENT_NAME-$WIREGUARD_PUB_NIC.conf"
          echo -e "Expired Date: $(date -d "$AKTIF days" +"%d-%m-%Y")"
        fi
