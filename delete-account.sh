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

if [ -x "$(command -v wg)" ]; then
          echo "Which WireGuard user do you want to remove?"
          # shellcheck disable=SC2002
          cat $WIREGUARD_CONFIG | grep start | awk '{ print $2 }'
          read -rp "Type in Client Name : " -e REMOVECLIENT
          read -rp "Are you sure you want to remove $REMOVECLIENT ? (y/n): " -n 1 -r
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i "/\# $REMOVECLIENT start/,/\# $REMOVECLIENT end/d" $WIREGUARD_CONFIG
            rm -f $WIREGUARD_CLIENT_PATH/"$REMOVECLIENT"-$WIREGUARD_PUB_NIC.conf
            echo "Client $REMOVECLIENT has been removed."
          elif [[ $REPLY =~ ^[Nn]$ ]]; then
            exit
          fi
          # Restart WireGuard
          if pgrep systemd-journal; then
            systemctl restart wg-quick@$WIREGUARD_PUB_NIC
          else
            service wg-quick@$WIREGUARD_PUB_NIC restart
          fi
        fi
