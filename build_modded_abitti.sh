#/bin/bash
debian_image_url="https://cdimage.debian.org/debian-cd/12.9.0-live/amd64/iso-hybrid/debian-live-12.9.0-amd64-gnome.iso"
abitti_image_url="https://static.abitti.fi/etcher-usb/koe-etcher.zip"
output_file="./abitti_mod.iso" # remember .iso

# Function to print the banner
print_banner() {
  echo " █████╗ ██████╗ ██╗████████╗████████╗██╗"
  echo "██╔══██╗██╔══██╗██║╚══██╔══╝╚══██╔══╝██║"
  echo "███████║██████╔╝██║   ██║      ██║   ██║"
  echo "██╔══██║██╔══██╗██║   ██║      ██║   ██║"
  echo "██║  ██║██████╔╝██║   ██║      ██║   ██║"
  echo "╚═╝  ╚═╝╚═════╝ ╚═╝   ╚═╝      ╚═╝   ╚═╝"
  echo "      ███╗   ███╗ ██████╗ ██████╗       "
  echo "      ████╗ ████║██╔═══██╗██╔══██╗      "
  echo "      ██╔████╔██║██║   ██║██║  ██║      "
  echo "      ██║╚██╔╝██║██║   ██║██║  ██║      "
  echo "      ██║ ╚═╝ ██║╚██████╔╝██████╔╝      "
  echo "      ╚═╝     ╚═╝ ╚═════╝ ╚═════╝       "
}

# Function to print a divider line
print_divider() {
  echo -e "\n----------------------------------------\n"
}

# Function to download Debian image
download_debian_image() {
  print_divider
  if [ -e debian.iso ]; then
    echo "debian.iso exists, skipping download."
  else
    echo "Downloading debian image"
    wget $debian_image_url -O debian.iso
  fi
}

# Function to download and extract Abitti image
download_and_extract_abitti() {
  print_divider
  if [ -e abitti.iso ]; then
    echo "Abitti image exists, skipping download."
  else
    echo "Abitti image required..."
    echo "--> Downloading abitti.iso from $abitti_image_url"
    wget $abitti_image_url -O abitti.iso
    #Extract files
    # echo "Extracting koe-etcher.zip"
    # 7z x koe-etcher.zip .
  fi
  echo "Extracting abitti.iso"
  7z x "abitti.iso"
}

# Function to handle Abitti filesystem
handle_abitti_filesystem() {
  print_divider
  if [ -d ytl ]; then
    echo "ytl directory exists"
    echo "--> proceeding"
    mkdir -p ./ytl/mount_point
    sudo umount ./ytl/mount_point || true # this just allows us to check if script has run earlier
    sudo mount -o loop,offset=$((450560 * 512)) ./ytl/koe.img ./ytl/mount_point/ # this may cause error, idk
    if [ -e ./ytl/mount_point/live/filesystem.squashfs ]; then
      rsync --progress ./ytl/mount_point/live/filesystem.squashfs ./filesystem.squashfs
    else
      echo "ERROR: filesystem.squashfs not found in ytl/mount_point. Maybe extraction has failed."
      exit 1
    fi
  else
    echo "ERROR: ytl directory not found. Maybe download or extraction has failed."
    exit 1
  fi
}

# Function to unsquash Abitti filesystem
unsquash_abitti() {
  print_divider
  if [ -e ./filesystem.squashfs ]; then
    echo "Unsquashing filesystem.squashfs"
    sudo unsquashfs ./filesystem.squashfs
    sudo rm ./filesystem.squashfs
  else
    echo "ERROR: filesystem.squashfs not found. Cannot unsquash."
    exit 1
  fi
}

# Function to extract Debian ISO
extract_debian_iso() {
  print_divider
  echo "Extracting debian.iso"
  sudo xorriso -osirrox on -indev debian.iso -extract / debian
}

# Function to modify the filesystem edit to suit ur needs if you want :=)
modify_filesystem() {
  print_divider
  echo "Add boot stuff"
  #Required for system to boot correctly (idk wtf this does)
  sudo cp -r ./5.10.0-21-amd64 ./squashfs-root/lib/modules/
  sudo cp -r ./5.10.0-20-amd64 ./squashfs-root/lib/modules/
  #Allow dhcp
  sudo sed -i 's/also require swap-server;//' ./squashfs-root/etc/dhcp/dhclient.conf
  #Remove firewall
  echo "Remove firewall"
  sudo find ./squashfs-root/etc/digabi/firewall.d -type f -exec sed -i 's/DROP/ACCEPT/g' {} +
  sudo sed -i 's/DROP/ACCEPT/g' ./squashfs-root/lib/live/config/0001-iptables-set-drop-policy
  sudo sed -i 's/^/#/' ./squashfs-root/usr/local/sbin/digabi-firewall-check
  sudo sed -i '/REJECT/d' ./squashfs-root/etc/digabi/firewall.d/9000-log-and-reject.v4.conf
  #Change release name to distinguish from unmodified Abitti
  # sudo sed -i 's/ABITTI/ABITTI_MOD/' ./squashfs-root/etc/digabios-release
  #Add root user with the name abitti_mod
  echo "Add root user with the name abitti_mod"
  echo "abitti_mod::0:0:root:/root:/bin/bash" | sudo tee -a ./squashfs-root/etc/passwd > /dev/null
  #Add user digabi to sudoers (default abitti user)
  echo "Add user digabi to sudoers (default abitti user)"
  sudo chmod 777 ./squashfs-root/etc/sudoers
  echo "digabi	ALL=(ALL:ALL) ALL" | sudo tee -a ./squashfs-root/etc/sudoers > /dev/null
  sudo chmod 440 ./squashfs-root/etc/sudoers
  #Allow user digabi to use terminal
  echo "Allow user digabi to use terminal"
  sudo sed -i 's/false/bash/' ./squashfs-root/lib/live/config/0031-lock-user-account
  sudo chmod +rx ./squashfs-root/usr/bin/terminator
  #Replace apt sources with the default debian sources
  echo "Replace apt sources with the default debian sources"  
  echo "deb http://deb.debian.org/debian bullseye main contrib non-free\ndeb-src http://deb.debian.org/debian bullseye main contrib non-free\ndeb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free\ndeb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free\ndeb http://deb.debian.org/debian bullseye-updates main contrib non-free\ndeb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" | sudo tee ./squashfs-root/etc/apt/sources.list > /dev/null
  #Disable mount backup check
  echo "Disable mount backup check"
  sudo sed -i 's/^/#/' ./squashfs-root/usr/local/sbin/mount-backup
}

# Function to create modified squashfs filesystem
create_modified_squashfs() {
  print_divider
  echo "Creating modified filesystem.squashfs"
  sudo mksquashfs ./squashfs-root ./filesystem.squashfs
  sudo mv ./filesystem.squashfs ./debian/live
}

# Function to modify grub config
modify_grub_config() {
  print_divider
  echo "Modifying grub config"
  sudo sed -i '13,30d' ./debian/boot/grub/grub.cfg
  sudo sed -i 's/menuentry "Debian GNU\/Linux Live (kernel 5.10.0-20-amd64)" {/menuentry "ABITTI_MOD" --unrestricted {/' ./debian/boot/grub/grub.cfg
  sudo sed -i 's/linux  \/live\/vmlinuz-5.10.0-20-amd64 boot=live components splash quiet "${loopback}"/linux  \/live\/vmlinuz-5.10.0-20-amd64 digabi=grub boot=live components nosplash debug config net.ifnames=0 union=overlay modules_load=i2c_hid,i2c-hid-acpi live-media-timeout=5 live-media-path=\/live panic=0 digabidata modprobe.blacklist=b44,b43,b43legacy,ssb,brcmsmac,bcma "${loopback}"/' ./debian/boot/grub/grub.cfg
}

# Function to modify isolinux menu.cfg
modify_isolinux_menu() {
  print_divider
  echo "Modifying isolinux menu"
  sudo sed -i 's/SAY "Booting Debian GNU\/Linux Live (kernel 5.10.0-20-amd64)..."/SAY "Booting ABITTI_MOD"/' ./debian/isolinux/menu.cfg
  sudo sed -i 's/APPEND initrd=\/live\/initrd.img-5.10.0-20-amd64 boot=live components splash quiet/APPEND initrd=\/live\/initrd.img-5.10.0-20-amd64 boot=live components nosplash debug/' ./debian/isolinux/menu.cfg
  sudo sed -i 's/Debian GNU\/Linux Live (kernel 5.10.0-20-amd64)/ABITTI_MOD/' ./debian/isolinux/menu.cfg
  sudo sed -i 's/MENU title Main Menu/MENU title ABITTI_MOD/' ./debian/isolinux/menu.cfg
  sudo sed -i '8,410d' ./debian/isolinux/menu.cfg
}

# Function to modify isolinux stdmenu.cfg
modify_isolinux_stdmenu() {
  print_divider
  echo "Modifying isolinux stdmenu"
  sudo sed -i 's/menu background splash.png/menu background ""/' ./debian/isolinux/stdmenu.cfg
}

# Function to build the ISO
build_iso() {
  print_divider
  sudo xorriso -outdev $output_file -volid "d-live 11.6.0 st amd64" -padding 0 -compliance no_emul_toc -map ./debian / -chmod 0755 / -- -boot_image isolinux dir=/isolinux -boot_image any next -boot_image any efi_path=boot/grub/efi.img -boot_image isolinux partition_entry=gpt_basdat
  echo -e "\e[32;1mdone\e[0m"
}

# Main script execution
print_banner
echo -n "Starting in: "
for i in {3..1}; do
  echo -n "$i "
  sleep 1
done
echo ""

if [ -d squashfs-root ]; then
  echo "squashfs-root exists, proceeding."
else
  echo "squashfs-root does not exist."
  echo "--> checking for other files"
  if [ -e filesystem.squashfs ]; then
    echo "filesystem.squashfs exists, proceeding."
  else
    download_and_extract_abitti
    handle_abitti_filesystem
    if [ -e filesystem.squashfs ]; then
      echo "filesystem.squashfs exists"
      echo "--> proceeding"
    else
      echo "ERROR: filesystem.squashfs not found. Maybe download or extraction has failed."
      exit 1
    fi
  fi
  unsquash_abitti
fi

if [ -d debian ]; then
  echo "debian directory exists, proceeding."
else
  echo "debian directory does not exist."
  echo "--> checking for other files"
  if [ -e debian.iso ]; then
    download_debian_image
  else
    echo "ERROR: debian.iso not found. Cannot proceed."
    exit 1
  fi
  extract_debian_iso
fi

modify_filesystem

# Pause for manual modifications
echo "Do manual modifications if necessary. Press Enter to continue...and create the iso"
read -p "Press Enter to continue..."

create_modified_squashfs
modify_grub_config
modify_isolinux_menu
modify_isolinux_stdmenu
build_iso