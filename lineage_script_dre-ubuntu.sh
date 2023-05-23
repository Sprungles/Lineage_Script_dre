#!/bin/bash

# Display warning for non-Ubuntu systems
echo "**********************************************************************"
echo "WARNING: This script is intended for Ubuntu. If you are using Fedora"
echo "or Arch Linux, please use the other scripts provided in the repository"
echo "you obtained this script from. Running this script on a non-Ubuntu"
echo "system may lead to unexpected behavior."
echo "**********************************************************************"
echo

# Enable parallel downloading in apt configuration
echo "Enabling parallel downloading in apt configuration..."
sudo sed -i 's/#Acquire::http::Pipeline-Depth/Acquire::http::Pipeline-Depth/g' /etc/apt/apt.conf.d/00aptitude
sudo sed -i 's/#Acquire::http::No-Cache/Acquire::http::No-Cache/g' /etc/apt/apt.conf.d/00aptitude
sudo sed -i 's/#Acquire::http::Max-Age/Acquire::http::Max-Age/g' /etc/apt/apt.conf.d/00aptitude
sudo sed -i 's/Acquire::http::Pipeline-Depth "5";/Acquire::http::Pipeline-Depth "50";/g' /etc/apt/apt.conf.d/00aptitude
sudo sed -i 's/Acquire::http::No-Cache "false";/Acquire::http::No-Cache "true";/g' /etc/apt/apt.conf.d/00aptitude
sudo sed -i 's/Acquire::http::Max-Age "0";/Acquire::http::Max-Age "86400";/g' /etc/apt/apt.conf.d/00aptitude

# Set up network optimization
echo "Setting up network optimization..."
sudo sysctl -w net.ipv4.tcp_keepalive_time=200
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=200
sudo sysctl -w net.ipv4.tcp_keepalive_probes=5
sudo sysctl -w net.core.rmem_default=31457280
sudo sysctl -w net.core.wmem_default=31457280
sudo sysctl -w net.core.rmem_max=12582912
sudo sysctl -w net.core.wmem_max=12582912
sudo sysctl -w net.ipv4.tcp_rmem="10240 87380 12582912"
sudo sysctl -w net.ipv4.tcp_wmem="10240 87380 12582912"
sudo sysctl -w net.ipv4.tcp_mtu_probing=1

# Configure DNS to use Quad9
echo "Configuring DNS..."
sudo sed -i '1s/^/nameserver 9.9.9.9\n/' /etc/resolv.conf
sudo sed -i '2s/^/nameserver 149.112.112.112\n/' /etc/resolv.conf
sudo sed -i '3s/^/nameserver 2620:fe::fe\n/' /etc/resolv.conf
sudo sed -i '4s/^/nameserver 2620:fe::9\n/' /etc/resolv.conf

# Prompt to enable Google's DNS
read -t 60 -rp "Do you want to use Google's DNS as well? (yes/no): " enable_google_dns
enable_google_dns=${enable_google_dns:-no}

if [ "$enable_google_dns" = "yes" ]; then
    # Configure DNS to use Google's DNS
    echo "Adding Google's DNS configuration..."
    sudo sed -i '5s/^/nameserver 8.8.8.8\n/' /etc/resolv.conf
    sudo sed -i '6s/^/nameserver 8.8.4.4\n/' /etc/resolv.conf
    sudo sed -i '7s/^/nameserver 2001:4860:4860::8888\n/' /etc/resolv.conf
    sudo sed -i '8s/^/nameserver 2001:4860:4860::8844\n/' /etc/resolv.conf
fi

# Configure DNS to use Cloudflare
sudo sed -i '9s/^/nameserver 1.1.1.1\n/' /etc/resolv.conf
sudo sed -i '10s/^/nameserver 1.0.0.1\n/' /etc/resolv.conf
sudo sed -i '11s/^/nameserver 2606:4700:4700::1111\n/' /etc/resolv.conf
sudo sed -i '12s/^/nameserver 2606:4700:4700::1001\n/' /etc/resolv.conf

# Check and install missing dependencies
echo "Checking and installing missing dependencies..."
declare -a missing_dependencies=("bc" "bison" "build-essential" "ccache" "curl" "flex" "g++-multilib" "gcc-multilib" "git" "gnupg" "gperf" "imagemagick" "lib32ncurses5-dev" "lib32readline-dev" "lib32z1-dev" "libc6-dev-i386" "liblz4-tool" "libncurses5" "libncurses5-dev" "libncursesw5" "libncursesw5-dev" "libsdl1.2-dev" "libssl-dev" "libxml2" "libxml2-utils" "lzop" "pngcrush" "rsync" "schedtool" "squashfs-tools" "sshpass" "sudo" "tar" "tmux" "wget" "xmlstarlet" "zip" "zlib1g-dev")

missing=()
for dependency in "${missing_dependencies[@]}"; do
    if ! dpkg -s "$dependency" >/dev/null 2>&1; then
        missing+=("$dependency")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
else
    echo "All necessary dependencies are already installed."
fi

# Set up the repo tool
echo "Setting up the repo tool..."
mkdir -p ~/bin
curl -sSL https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Create the build directory
echo "Creating the build directory..."
mkdir -p ~/android/lineage

# Navigate to the build directory
cd ~/android/lineage

# Initialize the LineageOS source repository
echo "Initializing LineageOS source repository..."
repo init -u https://github.com/LineageOS/android.git -b lineage-20 --depth=1 --groups=all,-notdefault,-darwin,-x86,-mips,-exynos5

# Sync the source code
echo "Syncing the source code. This might take a while..."
repo sync -c --no-tags --no-clone-bundle --optimized-fetch --prune -j"$(nproc --all)" --force-sync

# Clone the device-specific repository
echo "Cloning the device-specific repository..."
git clone --depth=1 https://github.com/LineageOS/android_device_oneplus_dre.git -b lineage-20 device/oneplus/dre

# Clone TheMuppets' proprietary vendor repository
echo "Cloning TheMuppets' proprietary vendor repository..."
git clone --depth=1 https://github.com/TheMuppets/proprietary_vendor_oneplus.git -b lineage-20 vendor/oneplus

# Clone the hardware-specific repository
echo "Cloning the hardware-specific repository"
git clone --depth=1 https://github.com/LineageOS/android_hardware_oplus.git -b lineage-20 hardware/oplus
# Clone the kernel lineage tree
echo "Cloning the kernel lineage tree..."
git clone --depth=1 https://github.com/tangalbert919/android_kernel_oneplus_sm4350.git -b lineage-20 kernel/oneplus/sm8150

# Enable ccache for faster subsequent builds
echo "Enabling ccache..."
export CCACHE_EXEC="$(which ccache)"
export USE_CCACHE=1
ccache -M 50G

# Set up environment variables
echo "Setting up environment variables..."
source build/envsetup.sh

# Build Lineage eon
echo "Installing additional dependencies for building Lineage eon..."
sudo apt-get install -y libssl-dev libssl1.1 liblz4-dev liblz4-tool python3 python3-pip python3-setuptools

# Install Python packages required for building Lineage eon
echo "Installing Python packages required for building Lineage eon..."
pip3 install --user pycryptodomex

# Start the build process
echo "Starting the build process..."
brunch dre

# Check for build errors
if [ "$?" -eq 0 ]; then
    # Build completed successfully
    echo -e "\n\e[5;41;1mBuild completed!\e[0m\n"
    spd-say -t male1 -r 50 "Build completed"
else
    # Build failed
    echo -e "\n\e[5;41;1mBuild failed!\e[0m\n"
fi

# Revert changes if requested
read -rp "Do you want to revert all changes made by this script? (yes/no): " revert_changes

if [ "$revert_changes" = "yes" ]; then
    echo "Reverting changes made by this script..."
    sudo sed -i '/nameserver/d' /etc/resolv.conf

    # Remove LineageOS source code
    echo "Removing LineageOS source code..."
    rm -rf ~/android/lineage

    # Remove repo tool
    echo "Removing repo tool..."
    rm -f ~/bin/repo
    sed -i '/export PATH=~/bin:$PATH/d' ~/.bashrc

    echo "Revert completed!"
else
    echo "Changes made by this script will remain on your system."
fi
