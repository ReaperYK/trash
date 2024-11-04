#!/usr/bin/env bash
################################################################################
#                                                                                                                                                                                                                                        #
# arch-installer - BlackArch Installer mod                                                                                                                                                        # 
#                                                                                                                                                                                                                                        #
# AUTHOR - noptrix(original) / ReaperYK(mod)                                                                                                                                              #
#                                                                                                                                                                                                                                         #
################################################################################

# version
VERSION='2.25.1'

# true / false
TRUE=0
FALSE=1

# return codes
SUCCESS=0
FAILURE=1

# colors and character
WHITE="$(tput setaf 7)"
# WHITEB="$(tput bold ; tput setaf 7)"
# BLUE="$(tput setaf 4)"
BLUEB="$(tput bold ; tput setaf 4)"
CYAN="$(tput setaf 6)"
CYANB="$(tput bold ; tput setaf 6)"
# GREEN="$(tput setaf 2)"
# GREENB="$(tput bold ; tput setaf 2)"
RED="$(tput setaf 1)"
# REDB="$(tput bold; tput setaf 1)"
YELLOW="$(tput setaf 3)"
# YELLOWB="$(tput bold ; tput setaf 3)"
BLINK="$(tput blink)"
NC="$(tput sgr0)"
QUE='!'
PLUS='+'

# chosen locale
LOCALE=''

# set locale
SET_LOCALE='1'

# list locales
LIST_LOCALE='2'

# chosen keymap
KEYMAP=''

# set keymap
SET_KEYMAP='1'

# list keymaps
LIST_KEYMAP='2'

# network interfaces
NET_IFS=''

# chosen network interface
NET_IF=''

# network configuration mode
NET_CONF_MODE=''

# network configuration modes
NET_CONF_AUTO='1'
NET_CONF_WLAN='2'
NET_CONF_MANUAL='3'
NET_CONF_SKIP='4'

# hostname
HOST_NAME=''

# host ipv4 address
HOST_IPV4=''

# gateway ipv4 address
GATEWAY=''

# subnet mask
SUBNETMASK=''

# broadcast address
BROADCAST=''

# nameserver address
NAMESERVER=''

# LUKS flag
LUKS=''
ASK_LUKS=""

# avalable hard drive
HD_DEVS=''

# chosen hard drive device
HD_DEV=''

# partition label: gpt or dos
PART_LABEL=''

# boot partition
BOOT_PART=''
BOOT_PART_FS=""

# root partition
ROOT_PART=''
ROOT_PART_FS=""

# crypted root
CRYPT_ROOT='r00t'

# swap partition
SWAP_PART=''

# chroot directory
CHROOT='/mnt'

# normal system user
NORMAL_USER=''

# default BlackArch Linux repository URL
BA_REPO_URL='https://ftp.halifax.rwth-aachen.de/blackarch/$repo/os/$arch' # Germany
#BA_REPO_URL='https://blackarch.cs.nycu.edu.tw/$repo/os/$arch' # Taiwan

# default ArchLinux repository URL
AR_REPO_URL='https://geo.mirror.pkgbuild.com/$repo/os/$arch' # Worldwide
AR_REPO_URL2='https://mirror.rackspace.com/archlinux/$repo/os/$arch' # Worldwide
AR_REPO_URL3='https://ftp.halifax.rwth-aachen.de/archlinux/$repo/os/$arch' # Germany


# X (display + window managers ) setup - default: false
#X_SETUP=$FALSE

# VirtualBox setup - default: false
VBOX_SETUP=$FALSE

# VMware setup - default: false
VMWARE_SETUP=$FALSE

# BlackArch Linux tools setup - default: false
BA_TOOLS_SETUP=$FALSE

# wlan ssid
WLAN_SSID=''

# wlan passphrase
WLAN_PASSPHRASE=''

# check boot mode
BOOT_MODE=''

# ascii art
ASCII='https://raw.githubusercontent.com/ReaperYK/trash/main/otherfile/rinuaa.txt'

BLACKARCH_SETUP=$FALSE

reflector_country=""

ctrl_c() {
    printf "\n"
    err 'Installation canceled! leaving...'
    printf "\n"
    swapoff "$SWAP_PART" > /dev/null 2>&1
    exit $FAILURE
}

trap ctrl_c 2

animation() {
  bar=0
  while [ $bar -ne $1 ]
  do
    wprintf "."
    sleep 1
    bar=$((bar + 1))
  done
}

# check exit status
check()
{
  es=$1
  func="$2"
  info="$3"

  if [ "$es" -ne 0 ]
  then
    echo
    warn "Something went wrong with $func. $info."
    sleep 5
  fi
}


# print formatted output
wprintf()
{
  fmt="${1}"

  shift
  printf "%s$fmt%s" "$WHITE" "$@" "$NC"

  return $SUCCESS
}

# print warning
warn()
{

  printf "[\033[33m${QUE}\033[0m] \033[33mWARNING:\033[0m \033[43m$@\033[0m"

  return $SUCCESS
}

printf1()
{

  printf "[\033[32m${PLUS}\033[0m] $@"

  return $SUCCESS
}

# print error and return failure
err()
{
  printf "[\033[31mX\033[0m] \033[31mERROR:\033[0m \033[41m$@\033[0m"

  return $FAILURE
}

# leet banner (very important)
banner()
{
  columns="$(tput cols)"
  str="--==[ Arch Linux Installer - ver $VERSION ]==--"

  printf "${BLUEB}%*s${NC}\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'

  echo "$str" |
  while IFS= read -r line
  do
    printf "%s%*s\n%s" "$CYANB" $(( (${#line} + columns) / 2)) \
      "$line" "$NC"
  done

  printf "${BLUEB}%*s${NC}\n\n\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'

  return $SUCCESS
}


# check boot mode
check_boot_mode()
{
  efivars=$(ls /sys/firmware/efi/efivars > /dev/null 2>&1; echo $?)
  if [ "$efivars" -eq "0" ]
  then
     BOOT_MODE="uefi"
  elif [ $FORCE_UEFI = "$TRUE" ]; then
     BOOT_MODE="uefi"
  fi

  return $SUCCESS
}


# sleep and clear
sleep_clear()
{
  sleep "$1"
  clear

  return $SUCCESS
}


# confirm user inputted yYnN
confirm()
{
  header="$1"
  ask="$2"

  while true
  do
    title "$header"
    wprintf "$ask"
    read -r input
    case $input in
      y|Y|yes|YES|Yes) return $TRUE ;;
      n|N|no|NO|No) return $FALSE ;;
      *) clear ; continue ;;
    esac
  done

  return $SUCCESS
}

# print menu title
title()
{
  banner
  printf "${CYAN}>> %s${NC}\n\n\n" "${@}"

  return "${SUCCESS}"
}


# check for environment issues
check_env()
{
  if [ -f '/var/lib/pacman/db.lck' ]
  then
    err "pacman locked - Please remove /var/lib/pacman/db.lck \n"
  fi
  
  if [ ! -e "/usr/bin/pacman" ];
  then
    warn "/bin/pacman not found."
    printf "\n"
  fi

  return $SUCCESS
}

# check user id
check_uid()
{
  if [ "$(id -u)" != '0' ]
  then
    err "You must be root to run the Arch installer!\n"
  fi

  return $SUCCESS
}


# set locale to use
set_locale()
{
  printf "[+] Welcome to Arch Linux Installer!\n"
  title 'Environment > Language Setup'
  wprintf '[+] Select Language'
  printf "\n"
  printf "
  1. English
  2. Japanese
  3. Other (Enter manually, show locale)
  \n"
  wprintf '[?] Set Language [2]: '
  read -r LANGUAGE

  if [ "$LANGUAGE" = "1" ]
  then
    LOCALE='en_US.UTF-8'
  fi

  if [ "$LANGUAGE" = "2" ]
  then
    LOCALE='ja_JP.UTF-8'
  fi

  if [ "$LANGUAGE" = "3" ]
  then
    printf "\n\n"
    vim -R /etc/locale.gen
    printf "\n\n[?] Please enter your locale: "
    read LOCALE
    if ! grep -q "^$LOCALE " /etc/locale.gen; then
     err "Invalid locale specified: $LOCALE" >&2
     exit 1
    fi
  fi

  # default locale
  if [ -z "$LANG" ]
  then
    echo
    warn 'Setting default locale: ja_JP.UTF-8'
    sleep 1
    LOCALE='ja_JP.UTF-8'
  fi

#  localectl set-locale "LANG=$LOCALE"
#  check $? 'setting locale'

  return $SUCCESS
}


# set keymap to use
set_keymap()
{
  title 'Environment > Keymap Setup'
  wprintf '[+] Select keymap'
  printf "\n"
  printf "
  1. English
  2. Japanese
  3. Other (Enter manually, show locale)
  \n"
  wprintf '[?] Set keymap [2]: '
  read -r KEYMP

  if [ "$KEYMP" = "1" ]
  then
    KEYMAP='us'
  fi

  if [ "$KEYMP" = "2" ]
  then
    KEYMAP='jp106'
  fi

  if [ "$KEYMP" = "3" ]
  then
    printf "\n\n"
    localectl list-keymaps
    printf "\n\n [?] enter keymap: "
    read KEYMAP
  fi

  # default keymap
  if [ -z "$KEYMP" ]
  then
    echo
    warn 'Setting default keymap: us'
    sleep 1
    KEYMAP='us'
  fi
  localectl set-keymap --no-convert "$KEYMAP"
  loadkeys "$KEYMAP"
  check $? 'setting keymap'

  return $SUCCESS
}


# enable multilib in pacman.conf if x86_64 present
enable_pacman_multilib()
{
  path="$1"

  if [ "$path" = 'chroot' ]
  then
    path="$CHROOT"
  else
    path=""
  fi

  title 'Pacman Setup > Multilib'

  if [ "$(uname -m)" = "x86_64" ]
  then
    printf1 'Enabling multilib support'
    printf "\n\n"
    if grep -q "#\[multilib\]" "$path/etc/pacman.conf"
    then
      # it exists but commented
      sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' "$path/etc/pacman.conf"
    elif ! grep -q "\[multilib\]" "$path/etc/pacman.conf"
    then
      # it does not exist at all
      printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
        >> "$path/etc/pacman.conf"
    fi
  fi

  return $SUCCESS
}


# enable color mode in pacman.conf
enable_pacman_color()
{
  path="$1"

  if [ "$path" = 'chroot' ]
  then
    path="$CHROOT"
  else
    path=""
  fi

  title 'Pacman Setup > Color'

  printf1 'Enabling color mode'
  printf "\n\n"

  sed -i 's/^#Color/Color/' "$path/etc/pacman.conf"

  return $SUCCESS
}

# update pacman package database
update_pkg_database()
{
  title 'Pacman Setup > Package Database'

  printf1 'Updating pacman database'
  printf "\n\n"

  pacman -Syy --noconfirm

  return $SUCCESS
}


# update pacman.conf and database
update_pacman()
{
  enable_pacman_multilib
  sleep_clear 1

  enable_pacman_color
  sleep_clear 1
  
  pacman_pdl_setup
  sleep_clear 1

  return $SUCCESS
}


# ask user for hostname
ask_hostname()
{
    title 'Network Setup > Hostname'
    wprintf '[?] Set your hostname: '
    read -r HOST_NAME

    if [ -z "$HOST_NAME" ]
    then
    warn 'Nothing was entered. set randomly...'
    sleep 1
    else
    return $SUCCESS
    fi
}

# get available network interfaces
get_net_ifs()
{
  NET_IFS="$(ip -o link show | awk -F': ' '{print $2}' |grep -v 'lo')"

  return $SUCCESS
}


# ask user for network interface
ask_net_if()
{
  while true
  do
    title 'Network Setup > Network Interface'
    wprintf '[+] Available network interfaces:'
    printf "\n\n"
    for i in $NET_IFS
    do
      echo "    > $i"
    done
    echo
    wprintf '[?] Please choose a network interface: '
    read -r NET_IF
    if echo "$NET_IFS" | grep "\<$NET_IF\>" > /dev/null
    then
      clear
      break
    fi
    clear
  done

  return $SUCCESS
}


# ask for networking configuration mode
ask_net_conf_mode()
{
  while [ "$NET_CONF_MODE" != "$NET_CONF_AUTO" ] && \
    [ "$NET_CONF_MODE" != "$NET_CONF_WLAN" ] && \
    [ "$NET_CONF_MODE" != "$NET_CONF_MANUAL" ] && \
    [ "$NET_CONF_MODE" != "$NET_CONF_SKIP" ]
  do
    title 'Network Setup > Network Interface'
    wprintf '[+] Network interface configuration:'
    printf "\n
  1. Auto DHCP (use this for auto connect via dhcp on selected interface)
  2. WiFi WPA Setup (use if you need to connect to a wlan before)
  3. Manual (use this if you are 1337)
  4. Skip (use this if you are already connected)\n\n"
    wprintf "[?] Please choose a mode: "
    read -r NET_CONF_MODE
    clear
  done

  return $SUCCESS
}


# ask for network addresses
ask_net_addr()
{
  while [ "$HOST_IPV4" = "" ] || \
    [ "$GATEWAY" = "" ] || [ "$SUBNETMASK" = "" ] || \
    [ "$BROADCAST" = "" ] || [ "$NAMESERVER" = "" ]
  do
    title 'Network Setup > Network Configuration (manual)'
    wprintf "[+] Configuring network interface $NET_IF via USER: "
    printf "\n
  > Host ipv4
  > Gateway ipv4
  > Subnetmask
  > Broadcast
  > Nameserver
    \n"
    wprintf '[?] Host IPv4: '
    read -r HOST_IPV4
    wprintf '[?] Gateway IPv4: '
    read -r GATEWAY
    wprintf '[?] Subnetmask: '
    read -r SUBNETMASK
    wprintf '[?] Broadcast: '
    read -r BROADCAST
    wprintf '[?] Nameserver: '
    read -r NAMESERVER
    clear
  done

  return $SUCCESS
}

# manual network interface configuration
net_conf_manual()
{
  title 'Network Setup > Network Configuration (manual)'
  printf1 "Configuring network interface '$NET_IF' manually: "
  printf "\n\n"

  ip addr flush dev "$NET_IF"
  ip link set "$NET_IF" up
  ip addr add "$HOST_IPV4/$SUBNETMASK" broadcast "$BROADCAST" dev "$NET_IF"
  ip route add default via "$GATEWAY"
  echo "nameserver $NAMESERVER" > /etc/resolv.conf

  return $SUCCESS
}


# auto (dhcp) network interface configuration
net_conf_auto()
{
  opts='-h noleak -i noleak -v ,noleak -I noleak -t 10'

  title 'Network Setup > Network Configuration (auto)'
  printf1 "Configuring network interface '$NET_IF' via DHCP: "
  printf "\n\n"

  dhcpcd "$opts" -i "$NET_IF"
  printf "\n\n Waiting for 10 seconds"
  bar=0
  while [ $bar -ne 10 ]
  do
    wprintf "."
    sleep 1
    bar=$((bar + 1))
  done
  return $SUCCESS
}


# ask for wlan data (ssid, wpa passphrase, etc.)
ask_wlan_data()
{
  while [ "$WLAN_SSID" = "" ] || [ "$WLAN_PASSPHRASE" = "" ]
  do
    title 'Network Setup > Network Configuration (WiFi)'
    wprintf "[+] Configuring network interface $NET_IF via W-LAN + DHCP: "
    printf "\n
  > W-LAN SSID
  > WPA Passphrase (will not echo)
    \n"
    wprintf "[?] W-LAN SSID: "
    read -r WLAN_SSID
    wprintf "[?] WPA Passphrase: "
    read -rs WLAN_PASSPHRASE
    clear
  done

  return $SUCCESS
}


# wifi and auto dhcp network interface configuration
net_conf_wlan()
{
  wpasup="$(mktemp)"
  dhcp_opts='-h noleak -i noleak -v ,noleak -I noleak -t 10'

  title 'Network Setup > Network Configuration (WiFi)'
  printf1 "Configuring network interface $NET_IF via W-LAN + DHCP: "
  printf "\n\n"

  wpa_passphrase "$WLAN_SSID" "$WLAN_PASSPHRASE" > "$wpasup"
  wpa_supplicant -B -c "$wpasup" -i "$NET_IF" 

  warn 'We need to wait a bit for wpa_supplicant and dhcpcd'

  bar=0
  while [ $bar -ne 10 ]
  do
  wprintf "_"
  sleep 1
  bar=$((bar + 1))
  done

  dhcpcd "$dhcp_opts" -i "$NET_IF"

  bar=0
  printf "\n\n"
  printf1 "Waiting for 10 seconds"
  while [ $bar -ne 10 ]
  do
  wprintf "."
  sleep 1
  bar=$((bar + 1))
  done

  return $SUCCESS
}


# check for internet connection
check_inet_conn()
{
  title 'Network Setup > Connection Check'
  printf1 'Checking for Internet connection'
  printf "\n\n"

  if ! curl -s $ASCII
  then
   if ! curl -s https://yahoo.com/
   then
    err 'No Internet connection! Check your network (settings).'
    exit $FAILURE
   fi
  fi
 
 sleep 2

}

pacman_pdl_setup()
{ 
  if [ "$1" = "chroot" ]; then
   title 'Pacman > Parallel Download'
   printf1 'Setting up /etc/pacman.conf'
   sed -i "s/#ParallelDownloads/ParallelDownloads/" "/mnt/etc/pacman.conf"
  else 
    title 'Pacman > Parallel Download'
    printf1 'Setting up /etc/pacman.conf'
    sed -i "s/#ParallelDownloads/ParallelDownloads/" "/etc/pacman.conf"
  fi

  return $SUCCESS
}

# live environment keyring is update
update_keyring()
{
	title 'Pacman Setup > Initialize keyring'

  printf1 'Initializing keyring'
	printf "\n\n"
	pacman -Syy archlinux-keyring --noconfirm
	return $SUCCESS
}

# get available hard disks
get_hd_devs()
{
  HD_DEVS="$(lsblk | grep disk | awk '{print $1}')"

  return $SUCCESS
}

cfdisk_manual()
{
  while true; do
  title 'Hard Drive Setup > using cfdisk manually'
  printf1 "Manual partition setup"
  printf '\n\n[+] Current partition configuration\n'
  sfdisk -l -q
  printf '\n\n[+] Configurable device\n\n'
  for i in $HD_DEVS
  do
  echo "    > ${i}"
  done
  echo
  echo "[z] zeroed partition"
  echo "[exit] finish partitioning"
  read -p "Enter device or options: " devchoice

  if [ "$devchoice" = "exit" ]; then
  printf '[?] Select the device on which to install the bootloader [Example: sda]: '
  read HD_DEV
  if echo "$HD_DEVS" | grep "\<$HD_DEV\>" > /dev/null
  then
   HD_DEV="/dev/$HD_DEV"
   clear
   break
  fi
  clear
  elif [ "$devchoice" = "z" ]; then
    read -p "[?] Enter device: " DEV
    cfdisk -z /dev/$DEV
    sync
    clear
  else
    cfdisk /dev/$devchoice
    sync
    clear
  fi
done

}

# get partition label
get_partition_label()
{
  if [ "$FORCE_UEFI" = "$TRUE" ]; then
   PART_LAVEL="gpt"
  else
   PART_LABEL="$(fdisk -l "$HD_DEV" | grep "Disklabel" | awk '{print $3;}')"
  fi

  return $SUCCESS
}

ask_partitions()
{
  while [ "$FINCHECK" != "y" ]
  do    
    BOOT_PART=""
    ROOT_PART=""
    title 'Hard Drive Setup > Partitions'
    printf1 'Created partitions:'
    printf "\n\n"

    sfdisk -l -q
    
    echo

    if [ "$BOOT_MODE" = 'uefi' ]  && [ "$PART_LABEL" = 'gpt' ]
    then
      while [ -z "$BOOT_PART" ]; do
        wprintf "[?] EFI System partition: "
        read -r BOOT_PART
        printf "\n"
      done
    else
      while [ -z "$BOOT_PART" ]; do
        wprintf "[?] Boot partition: "
        read -r BOOT_PART
        printf "\n"
        wprintf "[?] File System type (ext4,ext3,ext2,btrfs,empty to default): "
        read -r BOOT_PART_FS
      done
    fi
    printf "\n"
    while [ -z "$ROOT_PART" ]; do
      wprintf "[?] Root partition: "
      read -r ROOT_PART
      printf "\n"
      wprintf "[?] File System type (ext4,ext3,ext2,btrfs,empty to default): "
      read -r ROOT_PART_FS
    done
    wprintf "[?] Swap partition (empty for none): "
    read -r SWAP_PART
    printf "\n"

    wprintf "[?] activate LUKS [y/n]: "
    read -r ASK_LUKS
    
    if [ "$ASK_LUKS" = "y" ] && [ "$ASK_LUKS" ]; then
     LUKS=$TRUE
    else
     LUKS=$FALSE
    fi

    printf "\n\n"
    printf1 "Selected partition: \n\n"
    wprintf "Boot partition => $BOOT_PART \n"
    wprintf "Root partition => $ROOT_PART \n"
    wprintf "Swap partition => $SWAP_PART \n"
    printf "\n"

    printf1 "Are you sure you want to specify the partition [y/n]: "
    read FINCHECK 

    if [ "$SWAP_PART" = '' ]
    then
      SWAP_PART='none'
    fi
    clear

  done

  return $SUCCESS
}

make_partition() {
  if [ "$BOOT_MODE" = 'uefi' ]  && [ "$PART_LABEL" = 'gpt' ]
  then
  # boot partiton (UEFI)
   title 'Hard Drive Setup > Partition Formatting'
   wprintf '[+] Creating EFI System Partition'
   printf "\n\n"
   mkfs.vfat -F 32 $BOOT_PART
   sleep_clear 1
  else
   formatter "$BOOT_PART" "$BOOT_PART_FS" # boot partiton (MBR)
  fi

  # root partition
  if [ $LUKS = $TRUE ]
  then
    make_luks_partition "$ROOT_PART"
    sleep_clear 1
    open_luks_partition "$ROOT_PART" "$CRYPT_ROOT"
    sleep_clear 1
    formatter "/dev/mapper/$CRYPT_ROOT" "$ROOT_PART_FS"
    sleep_clear 1
  else
  formatter "$ROOT_PART" "$ROOT_PART_FS"
  fi

  return $SUCCESS
}

formatter() {
  target_partition="$1"
  target_filesystem="$2"
  
  if [ "$target_filesystem" = "ext4" ]; then
   format_command='mkfs.ext4 -m 0 -O ^64bit -F'
  elif [ "$target_filesystem" = "btrfs" ]; then
   format_command='mkfs.btrfs -f'
  elif [ "$target_filesystem" = "ext2" ]; then
   format_command='mkfs.ext2 -F -m 0'
  elif [ "$target_filesystem" = "ext3" ]; then
   format_command='mkfs.ext3 -F -m 0'
  else
   format_command='mkfs.ext4 -m 0 -O ^64bit -F'
  fi

  title "Hard Drive Setup > Partition Formatting"
  wprintf "[+] Formatting $target_partition"
  printf "\n\n"

  $format_command $target_partition ||
    { err 'Could not create filesystem'; exit $FAILURE; }

  sleep_clear 1
  return $SUCCESS
}

# ask user and get confirmation for formatting
ask_formatting()
{
  while [ "$CHECK_FMT" != "y" ]
  do
  title 'Hard Drive Setup > Partition Formatting'
  wprintf '[?] Formatting partitions. Are you sure? No crying afterwards? [y/n]: '
  read CHECK_FMT
  if [ "$CHECK_FMT" = "y" ]
  then
    break
  else
    echo
    err 'Seriously? No formatting no fun! Please format to continue or Ctrl+C to cancel...'
    sleep 3
    clear
  fi
  done
}

# create LUKS encrypted partition
make_luks_partition()
{
  part="$1"

  title 'Hard Drive Setup > Partition Creation (crypto)'

  printf1 'Creating LUKS partition'
  printf "\n\n"

  cryptsetup -q -y -v luksFormat "$part" \
     || { clear ; err 'Could not LUKS format, trying again.'; make_luks_partition "$@"; }

}

# open LUKS partition
open_luks_partition()
{
  part="$1"
  name="$2"

  title 'Hard Drive Setup > Partition Creation (crypto)'

  printf1 'Opening LUKS partition'
  printf "\n\n"
  cryptsetup open "$part" "$name"  ||
    { clear ;err 'Could not open LUKS device, please try again and make sure that your password is correct.'; open_luks_partition "$@"; }

}


# create swap partition
make_swap_partition()
{
  title 'Hard Drive Setup > Partition Creation (swap)'

  printf1 'Creating SWAP partition'
  printf "\n\n"
  mkswap $SWAP_PART  || { err 'Could not create filesystem'; exit $FAILURE; }

}

# make and format root partition
make_root_partition()
{
  if [ $LUKS = $TRUE ]
  then
    make_luks_partition "$ROOT_PART"
    sleep_clear 1
    open_luks_partition "$ROOT_PART" "$CRYPT_ROOT"
    sleep_clear 1
    title 'Hard Drive Setup > Partition Creation (root crypto)'
    printf1 'Creating encrypted ROOT partition'
    printf "\n\n"
      mkfs.ext4 -F "/dev/mapper/$CRYPT_ROOT"  ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    sleep_clear 1
  else
    title 'Hard Drive Setup > Partition Creation (root)'
    printf1 'Creating ROOT partition'
    printf "\n\n"
      mkfs.ext4 -F "$ROOT_PART"  ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    sleep_clear 1
  fi

  return $SUCCESS
}

# make and format boot partition
make_boot_partition()
{
  if [ "$BOOT_MODE" = 'uefi' ] && [ "$PART_LABEL" = 'gpt' ]
  then
    return $SUCCESS
  fi

  title 'Hard Drive Setup > Partition Creation (boot)'

  printf1 'Creating BOOT partition'
  printf "\n\n"
  if [ "$BOOT_MODE" = 'uefi' ] && [ "$PART_LABEL" = 'gpt' ]
  then
    mkfs.fat -F32 "$BOOT_PART"  ||
      { err 'Could not create filesystem'; exit $FAILURE; }
  else
    mkfs.ext4 -F "$BOOT_PART"  ||
      { err 'Could not create filesystem'; exit $FAILURE; }
  fi

  return $SUCCESS
}


# make and format partitions
make_partitions()
{
  make_partition
  sleep_clear 1

  if [ "$SWAP_PART" != "none" ]
  then
    make_swap_partition
    sleep_clear 1
  fi

  return $SUCCESS
}

# mount filesystems
mount_filesystems()
{
  title 'Hard Drive Setup > Mount'

  printf1 'Mounting filesystems'
  printf "\n\n"

  # ROOT
  if [ $LUKS = $TRUE ]; then
    if ! mount "/dev/mapper/$CRYPT_ROOT" $CHROOT; then
      err "Error mounting root filesystem, leaving."
      exit $FAILURE
    fi
  else
    if ! mount "$ROOT_PART" $CHROOT; then
      err "Error mounting root filesystem, leaving."
      exit $FAILURE
    fi
  fi

  # BOOT
  mkdir "$CHROOT/boot" 
  if ! mount "$BOOT_PART" "$CHROOT/boot"; then
    err "Error mounting boot partition, leaving."
    exit $FAILURE
  fi

  # SWAP
  if [ "$SWAP_PART" != "none" ]
  then
    swapon $SWAP_PART 
  fi

  return $SUCCESS
}


# unmount filesystems
umount_filesystems()
{
  routine="$1"

  if [ "$routine" = 'harddrive' ]
  then
    title 'Hard Drive Setup > Unmount'

    printf1 'Unmounting filesystems'
    printf "\n\n"

    umount -Rf /mnt > /dev/null 2>&1; \
    umount -Rf "$HD_DEV"{1..128} > /dev/null 2>&1 # gpt max - 128
    cryptsetup luksClose /dev/mapper/"$CRYPT_ROOT" 2>&1
  else
    title 'Game Over'

    printf1 'Unmounting filesystems'
    printf "\n\n"

    umount -Rf $CHROOT > /dev/null 2>&1
    cryptsetup luksClose "$CRYPT_ROOT" > /dev/null 2>&1
    swapoff $SWAP_PART > /dev/null 2>&1
  fi

  return $SUCCESS
}


# check for necessary space
check_space()
{
  if [ $LUKS -eq $TRUE ]
  then
    avail_space=$(df -m | grep "/dev/mapper/$CRYPT_ROOT" | awk '{print $4}')
  else
    avail_space=$(df -m | grep "$ROOT_PART" | awk '{print $4}')
  fi

  if [ "$avail_space" -le 40960 ]
  then
    warn 'Arch Linux requires at least 40 GB of free space to install!'
  fi

  return $SUCCESS
}

# install ArchLinux base and base-devel packages
install_base_packages()
{
  title 'Base System Setup > ArchLinux Packages'

  printf1 'Installing ArchLinux base packages'
  printf "\n\n"
  warn 'This can take a while, please wait...'
  printf "\n\n"
  
  if [ "$USE_LINUX_LTS" = "$TRUE" ]; then
  pacstrap $CHROOT base base-devel btrfs-progs linux-lts linux-firmware git \
    terminus-font zsh-completions grml-zsh-config wget aria2 --disable-download-timeout ||
   { err "Unable to install base system (wrong file system or mirror server problem?)"; exit $FAILURE; }
  else 
    pacstrap $CHROOT base base-devel btrfs-progs linux linux-firmware git \
    terminus-font zsh-completions grml-zsh-config wget aria2 --disable-download-timeout ||
   { err "Unable to install base system (wrong file system or mirror server problem?)"; exit $FAILURE; }
  fi

  return $SUCCESS
}


# setup /etc/resolv.conf
setup_resolvconf()
{
  if [ "$1" = "chroot" ]; then
  title 'Base System Setup > Etc'

  wprintf '[+] Setting up /etc/resolv.conf'
  printf "\n\n"

  mkdir -p "$CHROOT/etc/" 
  cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf" 
  
  if ! chroot /mnt curl -s $ASCII
  then
   echo "nameserver 8.8.8.8" >> /mnt/etc/resolv.conf
   chroot /mnt curl -s $ASCII || {
    err "Unable to connect to network on new system at chroot destination. Aborting."; exit $FAILURE; }
  fi
  
  else
  title 'Base System Setup > Etc'

  printf1 'Setting up /etc/resolv.conf'
  printf "\n\n"
   
  mkdir -p "$CHROOT/etc/" 
  cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf" 
  fi

  return $SUCCESS
}


# setup fstab
setup_fstab()
{
  title 'Base System Setup > Etc'

  printf1 'Setting up /etc/fstab'
  printf "\n\n"

  genfstab -U $CHROOT >> "$CHROOT/etc/fstab"

  sed 's/relatime/noatime/g' -i "$CHROOT/etc/fstab"

  return $SUCCESS
}

# setup locale and keymap
setup_locale()
{
  title 'Base System Setup > Locale'

  printf1 "Setting up $LOCALE locale"
  printf "\n\n"
  sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" "$CHROOT/etc/locale.gen"
  sed -i "s/^#$LOCALE/$LOCALE/" "$CHROOT/etc/locale.gen"
  chroot $CHROOT locale-gen 
  echo "LANG=$LOCALE" > "$CHROOT/etc/locale.conf"
  echo "KEYMAP=$KEYMAP" > "$CHROOT/etc/vconsole.conf"

  return $SUCCESS
}

# setup timezone
setup_time()
{
   title 'Base System Setup > Timezone'
   printf1 "Setting up Timezone"
   printf "\n"

   if [ "$LANGUAGE" = "2" ]
    then
	    timezone='Asia/Tokyo'
    else
      printf "[?] Default = UTC. Show list and select other time zone? [y/n]: "
      read -r manual_set_timezone
      if [ "$manual_set_timezone" = "y" ]; then
	     printf "\n"
       timedatectl list-timezones
       printf "\n\n [?] Enter time zone: "
       read timezone
      else
       timezone="UTC"
      fi    
    fi
    
    if [ -z "$timezone" ]
    then
      warn 'Do you live on Mars? Setting default time zone...'
      sleep 1
      default_time
    fi

  printf "\n\n"
  chroot $CHROOT ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

  return $SUCCESS

}

default_time()
{
  echo
  warn 'Setting up default time and timezone: UTC'
  printf "\n\n"
  chroot $CHROOT ln -sf /usr/share/zoneinfo/UTC /etc/localtime

  return $SUCCESS
}


# setup system clock
sync_clock()
{
	title 'Live Environment > Other settings'
	printf1 'Setting up system clock'
	timedatectl set-ntp true
  sleep 2
  hwclock --systohc

	return $SUCCESS

}


# setup initramfs
setup_initramfs()
{
  title 'Base System Setup > InitramFS'

  printf1 'Setting up InitramFS'
  printf "\n\n"

 # terminus font
 echo 'FONT=ter-114n' >> "$CHROOT/etc/vconsole.conf"

  if [ $LUKS = $TRUE ]; then
    sed -i 's/^\(HOOKS=(.*\))$/\1 encrypt)/' /mnt/etc/mkinitcpio.conf
  fi  
  
  printf "\n"
  warn 'This can take a while, please wait...'
  printf "\n\n"
  chroot $CHROOT mkinitcpio -P 

  return $SUCCESS
}


# mount /proc, /sys and /dev
setup_proc_sys_dev()
{
  title 'Base System Setup > Proc Sys Dev'

  printf1 'Setting up /proc, /sys and /dev'
  printf "\n\n"

  mkdir -p "${CHROOT}/"{proc,sys,dev} 

  mount -t proc proc "$CHROOT/proc" 
  mount --rbind /sys "$CHROOT/sys" 
  mount --make-rslave "$CHROOT/sys" 
  mount --rbind /dev "$CHROOT/dev" 
  mount --make-rslave "$CHROOT/dev" 

  return $SUCCESS
}


# setup hostname
setup_hostname()
{
  title 'Base System Setup > Hostname'

  printf1 'Setting up hostname'
  printf "\n\n"

  echo "$HOST_NAME" > "$CHROOT/etc/hostname"

  return $SUCCESS
}


# setup boot loader for UEFI/GPT or BIOS/MBR
setup_bootloader()
{
  title 'Base System Setup > Boot Loader'

  # common
  sed -i "s/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/g" "/mnt/etc/default/grub"
  sed -i 's/#GRUB_COLOR_/GRUB_COLOR_/g' "$CHROOT/etc/default/grub"
  
  if [ "$BOOT_MODE" = 'uefi' ] && [ "$PART_LABEL" = 'gpt' ]
  then
    printf1 'Setting up GRUB (EFI) boot loader'
    printf "\n\n"

    uuid="$(lsblk -o UUID "$ROOT_PART" | sed -n 2p)"

    if [ $LUKS = $TRUE ]
    then
      sed -i "s|loglevel=3 quiet|cryptdevice=UUID=$uuid:$CRYPT_ROOT root=/dev/mapper/$CRYPT_ROOT|" \
        "$CHROOT/etc/default/grub"
    fi

    echo "GRUB_BACKGROUND=\"/boot/grub/splash.png\"" >> \
      "$CHROOT/etc/default/grub"

    echo

    chroot $CHROOT grub-install --target=x86_64-efi --efi-directory=/boot --boot-directory=/boot --bootloader-id="archlinux" --recheck
    chroot $CHROOT grub-mkconfig -o /boot/grub/grub.cfg 
  else
    printf1 'Setting up GRUB boot loader'
    printf "\n\n"

    uuid="$(lsblk -o UUID "$ROOT_PART" | sed -n 2p)"

    if [ $LUKS = $TRUE ]
    then
      sed -i "s|loglevel=3 quiet|cryptdevice=UUID=$uuid:$CRYPT_ROOT root=/dev/mapper/$CRYPT_ROOT|" \
        "$CHROOT/etc/default/grub"
    fi

    echo "GRUB_BACKGROUND=\"/boot/grub/splash.png\"" >> \
      "$CHROOT/etc/default/grub"
    echo

    chroot $CHROOT grub-install --target=i386-pc --boot-directory=/boot --recheck "$HD_DEV" 
    chroot $CHROOT grub-mkconfig -o /boot/grub/grub.cfg 

  fi

  sed -i "s/GRUB_DISABLE_OS_PROBER/#GRUB_DISABLE_OS_PROBER/g" "/mnt/etc/default/grub"

  return $SUCCESS
}

# ask for normal user account to setup
ask_user_account()
{
  title 'Base System Setup > User'
  printf1 'User name: '
  read -r NORMAL_USER
  #ユーザー名が未入力の場合にランダムなユーザー名をセット
  if [ -z "$NORMAL_USER" ]; then
    users=("rineko" "ritora" "riken" "riusa")
    random_index=$(( RANDOM % ${#users[@]} ))
    NORMAL_USER=${users[$random_index]}
  fi

  return $SUCCESS
}

# setup user account, password and environment
setup_user()
{
  user="$(echo "$1" | tr -dc '[:alnum:]_' | tr '[:upper:]' '[:lower:]' |
    cut -c 1-32)"

  title 'Base System Setup > User'

  printf1 "Setting up $user account"
  printf "\n\n"
  if [ -n "$NORMAL_USER" ]; then
    chroot $CHROOT groupadd "$user" 
    chroot $CHROOT useradd -g "$user" -d "/home/$user" -s "/bin/bash" \
      -G "$user,wheel,users,video,audio" -m "$user" 
    chroot $CHROOT chown -R "$user":"$user" "/home/$user" 
    printf1 "Added user: $user"
    printf "\n\n"
  fi

  # password
  res=1337
  printf1 "Set password for $user: "
  printf "\n\n"
  while [ $res -ne 0 ]
  do
    if [ "$user" = "root" ]
    then
      chroot $CHROOT passwd
    else
      chroot $CHROOT passwd "$user"
    fi
    res=$?
  done

  return $SUCCESS
}

# reinitialize keyring (archlinux keyring only)
reinitialize_keyring()
{
  title 'Base System Setup > Keyring Reinitialization'

  printf1 'Reinitializing keyrings'
  printf "\n\n"

  chroot $CHROOT pacman -Syy --overwrite='*' --noconfirm archlinux-keyring
    

  return $SUCCESS
}

# install extra (missing) packages
setup_extra_packages()
{
   arch='arch-install-scripts pkgfile'
   bluetooth='bluez bluez-hid2hci bluez-tools bluez-utils'
   browser='chromium elinks firefox'
   editor='hexedit nano vim mousepad'
   filesystem='cifs-utils dmraid exfat-utils f2fs-tools efibootmgr dosfstools
   gpart gptfdisk mtools nilfs-utils ntfs-3g partclone parted partimage gparted os-prober grub'
   filemanager='thunar ark dolphin'
   media='ffmpeg yt-dlp mpv'
   audio='pipewire-alsa pipewire-pulse pavucontrol'
   hardware='amd-ucode intel-ucode'
   if [ "$USE_LINUX_LTS" = $TRUE ]; then
    kernel='linux-lts-headers'
   else
    kernel='linux-headers'
   fi
   misc='acpi git haveged hdparm htop inotify-tools ipython irssi
   linux-atm lsof mercurial mesa mlocate moreutils p7zip rsync neofetch lsb-release
   rtorrent screen scrot smartmontools strace tmux udisks2 unace unrar
   unzip upower usb_modeswitch usbutils zip fcitx5-im fcitx5-mozc python 
   ruby cmake curl python-pip'
   fonts='ttf-dejavu ttf-indic-otf ttf-liberation xorg-fonts-misc unicode-emoji noto-fonts-emoji noto-fonts noto-fonts-cjk noto-fonts-extra'
   network='atftp bind-tools bridge-utils darkhttpd dhclient dhcpcd dialog
   dnscrypt-proxy dnsmasq dnsutils fwbuilder iw networkmanager
   iwd lftp nfs-utils ntp openconnect openssh openvpn ppp pptpclient rfkill
   rp-pppoe socat vpnc wireless_tools wpa_supplicant wvdial xl2tpd'
   xorg='xorg rxvt-unicode xf86-video-amdgpu xf86-video-ati xorg-xclock
   xf86-video-dummy xf86-video-fbdev xf86-video-intel xf86-video-nouveau feh
   xf86-video-sisusb xf86-video-vesa xf86-video-vmware
   xf86-video-voodoo xorg-server xorg-xbacklight xorg-xinit xterm xorg-xlsfonts'

  all="$arch $bluetooth $browser $editor $filesystem $fonts $hardware $kernel"
  all="$all $misc $network $xorg $audio $media $filemanager"
  
  title 'Base System Setup > Extra Packages'
  printf1 'Installing extra packages'
  printf "\n\n"

  printf "
  > ArchLinux   : $(echo "$arch" | wc -w) packages
  > Browser     : $(echo "$browser" | wc -w) packages
  > Bluetooth   : $(echo "$bluetooth" | wc -w) packages
  > Editor      : $(echo "$editor" | wc -w) packages
  > Filesystem  : $(echo "$filesystem" | wc -w) packages
  > FileManager : $(echo "$filemanager" | wc -w) packages
  > Media       : $(echo "$media" | wc -w) packages
  > Audio       : $(echo "$audio" | wc -w) packages
  > Fonts       : $(echo "$fonts" | wc -w) packages
  > Hardware    : $(echo "$hardware" | wc -w) packages
  > Kernel      : $(echo "$kernel" | wc -w) packages
  > Misc        : $(echo "$misc" | wc -w) packages
  > Network     : $(echo "$network" | wc -w) packages
  > Xorg        : $(echo "$xorg" | wc -w) packages
  \n"

  warn 'This can take a while, please wait...'
  printf "\n"
  sleep 1

  chroot $CHROOT pacman -Sy --needed --overwrite='*' --noconfirm $all || { 
    err "Install failed. You will have to redo it manually later.";
    sleep 3; 
    chroot /mnt pacman -S --noconfirm --needed --overwrite="*" grub os-prober efibootmgr dosfstools networkmanager iwd;
    sleep_clear 1;
    return $SUCCESS; }

  return $SUCCESS
}

# perform system base setup/configurations
setup_base_system()
{
  pass_mirror_conf # copy mirror list to chroot env

  setup_resolvconf
  sleep_clear 1

  install_base_packages
  sleep_clear 1

  setup_resolvconf chroot
  sleep_clear 1
  
  setup_fstab
  sleep_clear 1

  setup_proc_sys_dev
  sleep_clear 1

  setup_locale
  sleep_clear 1

  enable_pacman_multilib 'chroot'
  sleep_clear 1

  enable_pacman_color 'chroot'
  sleep_clear 1

  setup_initramfs
  sleep_clear 1
  
  if [ -z "$HOST_NAME" ]
  then
  setup_user "root"
  sleep_clear 1

  ask_user_account
  sleep_clear 1

  setup_user "$NORMAL_USER"
  sleep_clear 1

  # hostname setup
  HOST_NAME="arch-$NORMAL_USER"

  setup_hostname
  sleep_clear 1
else
  setup_hostname
  sleep_clear 1

  setup_user "root"
  sleep_clear 1

  ask_user_account
  sleep_clear 1

  setup_user "$NORMAL_USER"
  sleep_clear 1
  fi

  if [ "$PACMANDL" = "WGET" ]
  then
  config_pacman_dl chroot
  sleep_clear 1
  fi

  pacman_pdl_setup chroot
  sleep_clear 1
  
  reinitialize_keyring
  sleep_clear 1
  
  disable_sign_check 2
  sleep_clear 1

  setup_extra_packages
  sleep_clear 1

  setup_bootloader
  sleep_clear 1

  return $SUCCESS
}


# enable systemd-networkd services
enable_iwd_networkmanager()
{
  title "Arch Linux Setup > Network"

  printf1 'Enabling Iwd and NetworkManager'
  printf "\n\n"

  chroot $CHROOT systemctl enable iwd NetworkManager

  return $SUCCESS
}

# update /etc files and set up iptables
update_etc()
{
  config_content='<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" compare="eq">
      <string>serif</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Noto Serif CJK JP</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" compare="eq">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Noto Sans CJK JP</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" compare="eq">
      <string>monospace</string>
    </test>
    <edit name="family" mode="assign" binding="strong">
      <string>Noto Mono</string>
    </edit>
  </match>
</fontconfig>'

  title "Arch Linux Setup > Etc files"
  wprintf '[+] Updating /etc files'
  printf "\n"
  
   if [ "$LOCALE"  = "ja_JP.UTF-8" ]; then
     echo "$config_content" | tee -a "/mnt/etc/fonts/local.conf" > /dev/null
   fi

  return $SUCCESS
}

# setting up fcitx5
setup_im()
{
  title "Arch Linux Setup > Fcitx5 Setup"
  wprintf '[+] Setting up /etc/environment'

  cp "/etc/environment" "/mnt/etc"
  chroot $CHROOT sed -i '5a GTK_IM_MODULE=fcitx5' "/etc/environment"
  chroot $CHROOT sed -i '6a QT_IM_MODULE=fcitx5' "/etc/environment"
  chroot $CHROOT sed -i '7a XMODIFIERS=@im=fcitx5' "/etc/environment"
  printf "\n"

  sleep 1

  return $SUCCESS
}

ask_blackarch_mirror_setup()
{
  title "ArchLinux Setup > BlackArch Mirror / keyring Setup"
  wprintf '[?] Setup BlackArch keyring and mirror server [y/n] [If you are not sure, press "n"]: '
  read ASK_BLACKARCH_SETUP

  if [ "$ASK_BLACKARCH_SETUP" = "y" ]; then
   BLACKARCH_SETUP=$TRUE
  fi

  return 0
}

# ask for BlackArch Linux lmirror
ask_mirror()
{
  title "BlackArch Linux Setup > Arch Linux Mirror"

  local IFS='|'
  count=1
  mirror_url='https://raw.githubusercontent.com/BlackArch/blackarch/master/mirror/mirror.lst'
  mirror_file='/tmp/mirror.lst'

  printf1 'Fetching mirror list'
  printf "\n\n"
  curl -s -o $mirror_file $mirror_url

  while read -r country url mirror_name
  do
    wprintf " %s. %s - %s" "$count" "$country" "$mirror_name"
    printf "\n"
    wprintf "   * %s" "$url"
    printf "\n"
    count=$((count + 1))
  done < "$mirror_file"

  printf "\n"
  wprintf '[?] Select a mirror number (enter for default): '
  read -r a
  printf "\n"

  # bugfix: detected chars added sometimes - clear chars
  _a=$(printf "%s" "$a" | sed 's/[a-z]//Ig' 2> /dev/null)

  if [ -z "$_a" ]
  then
    printf1 "Choosing default mirror: %s " $BA_REPO_URL
  else
    BA_REPO_URL=$(sed -n "${_a}p" $mirror_file | cut -d "|" -f 2)
    printf "[+] Mirror from '%s' selected" \
      "$(sed -n "${_a}p" $mirror_file | cut -d "|" -f 3)"
    printf "\n\n"
  fi

  rm -f $mirror_file

  return $SUCCESS
}

setup_mirrorlist()
{
   local mirrold='cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup'

  if confirm 'Pacman Setup > ArchLinux Mirrorlist' \
    "[+] Worldwide mirror will be used\n\n[?] Look for the best server [y/n]: "
  then
    printf "\n"
    wprintf '[?] Specify the country of the mirror server (for example: "United States","Canada","Japan","China","Korea") [Enter to set as Default]: '
    read -r reflector_country
    if [ -z "$reflector_country" ]; then
     warn "Set to Default(EU)."
     printf "\n"
     reflector_country=""
    fi

    printf "\n"
    warn 'This may take time depending on your connection'
    printf "\n"
    $mirrold
    pacman -Sy --noconfirm
    pacman -S --needed --noconfirm reflector
    yes | pacman -Scc
    reflector --verbose --latest 5 -c "$reflector_country" --protocol https --sort rate \
      --save /etc/pacman.d/mirrorlist || { err "mirror setup failed. Aborting..."; exit 1; }
  else
    printf "\n"
    warn 'Using Worldwide mirror server'
    $mirrold
    echo -e "## Arch Linux repository Worldwide mirrorlist\n\n" \
      > /etc/pacman.d/mirrorlist
    echo "Server = $AR_REPO_URL" >> /etc/pacman.d/mirrorlist
    echo "Server = $AR_REPO_URL2" >> /etc/pacman.d/mirrorlist
    echo "Server = $AR_REPO_URL3" >> /etc/pacman.d/mirrorlist
  fi
}

# pass correct config
pass_mirror_conf()
{
  mkdir -p "$CHROOT/etc/pacman.d/" 
  cp -f /etc/pacman.d/mirrorlist "$CHROOT/etc/pacman.d/mirrorlist" \
    
}


# run strap.sh
run_strap_sh()
{
  strap_sh='/tmp/strap.sh'
  orig_sha1="$(curl -s https://blackarch.org/checksums/strap | awk '{print $1}')"

  title "BlackArch Linux > Strap"

  printf1 'Downloading and executing strap.sh'
  printf "\n\n"
  warn 'This can take a while, please wait...'
  printf "\n\n"

  curl -s -o $strap_sh 'https://www.blackarch.org/strap.sh' 
  sha1="$(sha1sum $strap_sh | awk '{print $1}')"

  printf '[blackarch]\nServer = %s\n' "$BA_REPO_URL" \
    >> "$CHROOT/etc/pacman.conf"

  if [ "$sha1" = "$orig_sha1" ]
  then
    printf "\n\n"
    mv $strap_sh "${CHROOT}${strap_sh}"
    chmod a+x "${CHROOT}${strap_sh}"
    chroot /mnt $strap_sh 
  else
    { err "Wrong SHA1 sum for strap.sh: $sha1 (orig: $orig_sha1). Aborting!"; exit $FAILURE; }
  fi
  
	printf "\n\n"
	chroot $CHROOT pacman -Sy archlinux-keyring blackarch-keyring --noconfirm

  return $SUCCESS
}


# temporarily disable pacman signature check
disable_sign_check()
{
	title 'Pacman Settings > Signature Check'
	wprintf '[+] Setting up /etc/pacman.conf'
	printf "\n\n"

	if [ "$1" = "1" ]; then
	      sed -i "s/Required DatabaseOptional/Never/" "/etc/pacman.conf"
        sed -i "s/LocalFileSigLevel/#LocalFileSigLevel/" "/etc/pacman.conf"
  elif [ "$1" = "2" ]; then  
	      sed -i "s/Required DatabaseOptional/Never/" "/mnt/etc/pacman.conf"
        sed -i "s/LocalFileSigLevel/#LocalFileSigLevel/" "/mnt/etc/pacman.conf"
elif [ "$1" = "3" ]; then
	      sed -i "s/Never/Required DatabaseOptional/" "/mnt/etc/pacman.conf"
        sed -i "s/#LocalFileSigLevel/LocalFileSigLevel/" "/mnt/etc/pacman.conf"
fi
	return $SUCCESS

}

ask_de_setup() {
  title "Arch Linux Setup > Desktop"
  printf "[?] Setup desktop (GNOME, KDE, LXDE) [y/n]: "
  read ASK_DE
  
  if [ "$ASK_DE" = "y" ]; then
   DE_SETUP=$TRUE
  else
   DE_SETUP=$FALSE
  fi

}

# select desktop
setup_de()
{
  title "Arch Linux Setup > Desktop"
  printf "
  1. KDE Plasma
  2. GNOME
  3. Xfce4
  4. LXDE \n\n"
  printf "[?] Choose [default=2]: "
  read choose_de

  if [ $choose_de = 1 ]; then
  DE_MAIN='plasma'
	DE_EXTPKG='kde-applications spectacle'
	DE_MAN='sddm'
  DE_TITLE='KDE Plasma'
  elif [ $choose_de = 2 ]; then
  DE_MAIN='gnome'
	DE_EXTPKG='gnome-keyring gnome-screenshot gnome-extra'
	DE_MAN='gdm'
  DE_TITLE='GNOME'
  elif [ $choose_de = 3 ]; then
  DE_MAIN='xfce4'
	DE_EXTPKG='gnome-keyring xfce4-goodies spectacle'
	DE_MAN='sddm'
  DE_TITLE='Xfce4'
  elif [ $choose_de = 4 ]; then
  DE_MAIN='lxde'
	DE_EXTPKG='lxde-common lxsession openbox spectacle'
	DE_MAN='lxdm'
  DE_TITLE='LXDE'
  elif [ -z $choose_de ]; then
  DE_MAIN='plasma'
	DE_EXTPKG='kde-applications spectacle'
	DE_MAN='sddm'
  DE_TITLE='KDE Plasma'
  choose_de=1
  fi

	chroot $CHROOT pacman -S $DE_MAIN $DE_EXTPKG $DE_MAN --disable-download-timeout --needed --noconfirm
	
  chroot $CHROOT systemctl enable $DE_MAN
	sleep 1

	return $SUCCESS
}


# ask user for VirtualBox modules+utils setup
ask_vbox_setup()
{
  if confirm "Arch Linux Setup > VirtualBox" '[?] Setup VirtualBox modules [y/n]: '
  then
    VBOX_SETUP=$TRUE
  fi

  return $SUCCESS
}


# setup virtualbox utils
setup_vbox_utils()
{
  title "Arch Linux Setup > VirtualBox"

  printf1 'Setting up VirtualBox utils'
  printf "\n\n"

  chroot $CHROOT pacman -S virtualbox-guest-utils --overwrite='*' --needed \
    --noconfirm 

  chroot $CHROOT systemctl enable vboxservice 

  #printf "vboxguest\nvboxsf\nvboxvideo\n" \
  #  > "$CHROOT/etc/modules-load.d/vbox.conf"

  return $SUCCESS
}


# ask user for VirtualBox modules+utils setup
ask_vmware_setup()
{
  if confirm "Arch Linux Setup > VMware" '[?] Setup VMware modules [y/n]: '
  then
    VMWARE_SETUP=$TRUE
  fi

  return $SUCCESS
}

# setup vmware utils
setup_vmware_utils()
{
  title "Arch Linux Setup > VMware"

  printf1 'Setting up VMware utils'
  printf "\n\n"

  chroot $CHROOT pacman -S open-vm-tools xf86-video-vmware \
    xf86-input-vmmouse --overwrite='*' --needed --noconfirm \
    

  chroot $CHROOT systemctl enable vmware-vmblock-fuse.service 
  chroot $CHROOT systemctl enable vmtoolsd.service 

  return $SUCCESS
}


# add user to newly created groups
update_user_groups()
{
  title "Arch Linux Setup > User"

  printf1 "Adding user $user to groups and sudoers"
  printf "\n\n"

  # TODO: more to add here
  if [ $VBOX_SETUP -eq $TRUE ]
  then
    chroot $CHROOT usermod -aG 'vboxsf,audio,video' "$user" 
  fi

  # sudoers
  echo "$user ALL=(ALL:ALL) ALL" >> $CHROOT/etc/sudoers 
  echo "root ALL=(ALL:ALL) ALL" >> $CHROOT/etc/sudoers

  return $SUCCESS
}


# setup archlinux related stuff
setup_extrasystem()
{
  update_etc
  sleep_clear 1

  if [ $LOCALE = "ja_JP.UTF-8" ]; then
   setup_im
   sleep_clear 1
  fi

  enable_iwd_networkmanager
  sleep_clear 1
  
  ask_blackarch_mirror_setup
  sleep_clear 1

  if [ $BLACKARCH_SETUP = $TRUE ]; then
   ask_mirror
   sleep_clear 1
   run_strap_sh
   sleep_clear 1
  fi

  ask_de_setup
  sleep_clear 1

  if [ "$DE_SETUP" = "$TRUE" ]
  then
	 setup_de
	 sleep_clear 1
  fi

  ask_vbox_setup
  sleep_clear 1

  if [ $VBOX_SETUP -eq $TRUE ]
  then
    setup_vbox_utils
    sleep_clear 1
  fi
  
  ask_vmware_setup
  sleep_clear 1

  if [ $VMWARE_SETUP -eq $TRUE ]
  then
    setup_vmware_utils
    sleep_clear 1
  fi

  update_user_groups
  sleep_clear 1

  return $SUCCESS
}


# for fun and lulz
easter_backdoor()
{
  bar=0

  title 'Game Over'
  wprintf "[+] Arch Linux installation successfull!"

  printf "\n\n"
  wprintf 'Yo n00b, b4ckd00r1ng y0ur sy5t3m n0w '
  while [ $bar -ne 5 ]
  do
    wprintf "."
    sleep 1
    bar=$((bar + 1))
  done

  printf " >> ${BLINK}${WHITE}HACK THE PLANET! STRAWBERRY PLANET!${NC} <<"
  printf "\n\n"

  return $SUCCESS
}

# perform sync
sync_disk()
{
  title 'Game Over'

  printf1 'Syncing disk'
  printf "\n\n"

  sync

  return $SUCCESS
}

# run update-initramfs
run_update_initramfs()
{
	title 'Game Over'

	printf1 'Updating InitramFS'
	printf "\n\n"
	chroot $CHROOT mkinitcpio -P

	return $SUCCESS

}

config_pacman_dl()
{
  title 'Pacman Settings > Download Options'
  printf1 'Setting up /etc/pacman.conf'
  if [ "$1" = "liveenv" ]; then
   sed -i '20 s/^#//' /etc/pacman.conf
  elif [ "$1" = "chroot" ]; then
   sed -i '20 s/^#//' /mnt/etc/pacman.conf
  fi

  return $SUCCESS
}

# controller and program flow
main()
{
  # do some ENV checks
  sleep_clear 0
  check_uid
  check_boot_mode
  check_env
  
  setfont ter-114n || {
    warn "Could not change font ";
    printf "\n";
  }
  # locale
  set_locale
  sleep_clear 0

  # keymap
  set_keymap
  sleep_clear 0

  # network
  ask_hostname
  sleep_clear 0

  sync_clock
  sleep_clear 1
  
  title 'Environment check > Network connection'
  printf1 "Checking internet connection"
  printf "\n\n"
  if ! curl -s $ASCII
  then
   if ! curl -s https://yahoo.com
   then
    sleep_clear 0.5
    get_net_ifs
    ask_net_conf_mode
    if [ "$NET_CONF_MODE" != "$NET_CONF_SKIP" ]
    then
      ask_net_if
    fi
    case "$NET_CONF_MODE" in
      "$NET_CONF_AUTO")
        net_conf_auto
        ;;
      "$NET_CONF_WLAN")
        ask_wlan_data
        net_conf_wlan
        ;;
      "$NET_CONF_MANUAL")
        ask_net_addr
        net_conf_manual
        ;;
      "$NET_CONF_SKIP")
        ;;
      *)
        ;;
    esac
    sleep_clear 1
    sync_clock
    sleep_clear 1
    check_inet_conn
    sleep_clear 1
   fi
  fi
  
  sleep_clear 1

  # hard drive
  get_hd_devs
  umount_filesystems 'harddrive'
  sleep_clear 1
  cfdisk_manual
  sleep_clear 1
  get_partition_label

  ask_partitions
  sleep_clear 1

  ask_formatting
  sleep_clear 1

  make_partitions
  clear
  mount_filesystems
  sleep_clear 1

  # truble fixing
  disable_sign_check 1
  sleep_clear 1

  setup_mirrorlist
  sleep_clear 1

  update_keyring
  sleep_clear 1

  update_pacman

  setup_base_system
  sleep_clear 1
  setup_time
  sleep_clear 1

  setup_extrasystem
  sleep_clear 1
  
  # epilog
  disable_sign_check 3
  sleep_clear 1
  run_update_initramfs
  sleep_clear 1
  umount_filesystems
  sleep_clear 1
  sync_disk
  sleep_clear 1
  easter_backdoor

  return $SUCCESS
}

# we start here
main

# EOF

