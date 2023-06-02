#!/bin/bash

# Check if running on Ubuntu
if ! grep -iq "ubuntu" /etc/os-release; then
    echo -e "\n\e[1;31mERROR: This script is designed to run on Ubuntu. Please use the appropriate script for your distribution.\e[0m\n"
    exit 1
fi

# Display warning for non-Ubuntu users
echo -e "\n\e[1;33mYOU NEED TO BE ON UBUNTU FOR THIS SCRIPT TO WORK. IF YOU WANT TO USE FEDORA OR ARCH, USE THE OTHER SCRIPTS IN THE REPOSITORY YOU GOT THIS FROM\e[0m\n"

# Delay for user to read the warning
sleep 5

# Prompt for network configuration optimization
read -p "Do you want to optimize network configuration for faster downloads and builds? (y/n): " network_optimization

# Network configuration optimization
if [[ $network_optimization =~ ^[Yy]$ ]]; then
    echo "Optimizing network configuration..."

    # Enable parallel downloading in apt configuration
    sudo sed -i '/Acquire::http::Pipeline-Depth/s/^#//' /etc/apt/apt.conf.d/99parallel
fi

# Remove old LineageOS source code and .repo folders
echo "Removing old LineageOS source code..."
rm -rf ~/android/lineage
rm -rf ~/.repo

# Initialize repo tool
echo "Initializing repo tool..."
cd ~
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Update the system
echo "Updating the system..."
sudo apt update
sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y openjdk-11-jdk git gnupg flex bison gperf g++ zip zlib1g-dev libncurses5-dev pkg-config libssl-dev libxml2-utils xsltproc unzip python3 python3-pip python3-setuptools wget

# Clone the LineageOS source repository
echo "Cloning the LineageOS source repository..."
mkdir -p ~/android/lineage
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0
repo sync -c --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)

# Clone the device-specific repository
echo "Cloning the device-specific repository..."
git clone --depth=1 https://github.com/tangalbert919/android_device_oneplus_dre.git -b lineage-20.0 device/oneplus/dre

# Clone TheMuppets' proprietary vendor repository
echo "Cloning TheMuppets' proprietary vendor repository..."
git clone --depth=1 https://github.com/TheMuppets/proprietary_vendor_oneplus.git -b lineage-20.0 vendor/oneplus

# Clone the kernel lineage tree
echo "Cloning the kernel lineage tree..."
git clone --depth=1 https://github.com/tangalbert919/android_kernel_oneplus_sdm450.git -b lineage-20.0 kernel/oneplus/sdm450

# Enable ccache for faster subsequent builds
export USE_CCACHE=1
ccache -M 50G

# Set up environment variables
export LC_ALL=C
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx8G"

# Build LineageOS
echo "Building LineageOS..."
source build/envsetup.sh
lunch lineage_dre-userdebug
make bacon -j$(nproc --all)

# Build completed!
echo -e "\n\e[1;35mBuild completed!\e[0m\n"

# Play sound notification
paplay /usr/share/sounds/freedesktop/stereo/complete.oga

# Prompt to install Revanced MicroG
read -p "Do you want to install Revanced MicroG? (y/n): " install_microg

if [[ $install_microg =~ ^[Yy]$ ]]; then
    # Clone Revanced MicroG repository
    echo "Cloning Revanced MicroG repository..."
    git clone --depth=1 https://github.com/TeamVanced/VancedMicroG.git packages/apps/VancedMicroG

    # Build Revanced MicroG
    echo "Building Revanced MicroG..."
    make VancedMicroG -j$(nproc --all)

    # Install Revanced MicroG
    echo "Installing Revanced MicroG..."
    adb root
    adb remount
    adb sync packages/apps/VancedMicroG/out/target/product/dre/system/priv-app/VancedMicroG

    echo -e "\n\e[1;35mRevanced MicroG installed successfully!\e[0m\n"
fi

# Revert changes prompt
read -p "Do you want to revert all changes made by this script? (y/n): " revert_changes

if [[ $revert_changes =~ ^[Yy]$ ]]; then
    # Revert network configuration optimization
    if [[ $network_optimization =~ ^[Yy]$ ]]; then
        echo "Reverting network configuration optimization..."

        # Disable parallel downloading in apt configuration
        sudo sed -i '/Acquire::http::Pipeline-Depth/s/^/#/' /etc/apt/apt.conf.d/99parallel
    fi

    echo "Removing DNS configuration..."
    sudo sed -i '/nameserver/d' /etc/resolv.conf

    echo "Removing LineageOS source..."
    rm -rf ~/android/lineage

    echo -e "\n\e[1;35mReverted all changes made by this script!\e[0m\n"
fi
