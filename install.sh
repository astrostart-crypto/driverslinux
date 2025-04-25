#!/bin/bash

# Скрипт для автоматической установки драйверов в различных дистрибутивах Linux
# Поддерживает: Arch Linux, Debian/Ubuntu, Fedora, openSUSE, Gentoo и другие

# Проверка на root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт должен запускаться с правами root!" >&2
    exit 1
fi

# Определение дистрибутива
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/gentoo-release ]; then
        DISTRO="gentoo"
    else
        DISTRO="unknown"
    fi
}

# Установка драйверов для Arch Linux
install_arch() {
    echo "Установка драйверов для Arch Linux..."
    pacman -Sy --noconfirm
    
    # Базовая установка
    pacman -S --noconfirm linux-headers base-devel
    
    # Определение GPU и установка драйверов
    if lspci | grep -i "nvidia" > /dev/null; then
        echo "Обнаружена видеокарта NVIDIA, устанавливаю драйвера..."
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    fi
    
    if lspci | grep -i "amd" > /dev/null; then
        echo "Обнаружена видеокарта AMD, устанавливаю драйвера..."
        pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon libva-mesa-driver
    fi
    
    # Wi-Fi драйверы
    pacman -S --noconfirm networkmanager wireless_tools wpa_supplicant
}

# Установка драйверов для Debian/Ubuntu
install_debian() {
    echo "Установка драйверов для Debian/Ubuntu..."
    apt update
    apt install -y build-essential linux-headers-generic
    
    # NVIDIA
    if lspci | grep -i "nvidia" > /dev/null; then
        echo "Обнаружена видеокарта NVIDIA, устанавливаю драйвера..."
        apt install -y nvidia-driver nvidia-settings
    fi
    
    # AMD
    if lspci | grep -i "amd" > /dev/null; then
        echo "Обнаружена видеокарта AMD, устанавливаю драйвера..."
        apt install -y libdrm-amdgpu1 xserver-xorg-video-amdgpu mesa-vulkan-drivers
    fi
    
    # Wi-Fi
    apt install -y network-manager wireless-tools wpasupplicant firmware-realtek firmware-atheros
}

# Установка драйверов для Fedora
install_fedora() {
    echo "Установка драйверов для Fedora..."
    dnf update -y
    dnf install -y kernel-devel kernel-headers gcc make
    
    # NVIDIA
    if lspci | grep -i "nvidia" > /dev/null; then
        echo "Обнаружена видеокарта NVIDIA, устанавливаю драйвера..."
        dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    fi
    
    # AMD
    if lspci | grep -i "amd" > /dev/null; then
        echo "Обнаружена видеокарта AMD, устанавливаю драйвера..."
        dnf install -y xorg-x11-drv-amdgpu mesa-vulkan-drivers
    fi
    
    # Wi-Fi
    dnf install -y NetworkManager wireless-tools wpa_supplicant
}

# Установка драйверов для openSUSE
install_opensuse() {
    echo "Установка драйверов для openSUSE..."
    zypper refresh
    zypper install -y kernel-devel gcc make
    
    # NVIDIA
    if lspci | grep -i "nvidia" > /dev/null; then
        echo "Обнаружена видеокарта NVIDIA, устанавливаю драйвера..."
        zypper install -y nvidia-computeG04 nvidia-glG04
    fi
    
    # AMD
    if lspci | grep -i "amd" > /dev/null; then
        echo "Обнаружена видеокарта AMD, устанавливаю драйвера..."
        zypper install -y xf86-video-amdgpu
    fi
    
    # Wi-Fi
    zypper install -y NetworkManager wpa_supplicant wireless-tools
}

# Установка драйверов для Gentoo
install_gentoo() {
    echo "Установка драйверов для Gentoo..."
    emerge --sync
    
    # NVIDIA
    if lspci | grep -i "nvidia" > /dev/null; then
        echo "Обнаружена видеокарта NVIDIA, устанавливаю драйвера..."
        emerge x11-drivers/nvidia-drivers
    fi
    
    # AMD
    if lspci | grep -i "amd" > /dev/null; then
        echo "Обнаружена видеокарта AMD, устанавливаю драйвера..."
        emerge x11-drivers/xf86-video-amdgpu
    fi
    
    # Wi-Fi
    emerge net-wireless/iw net-wireless/wpa_supplicant
}

# Основная функция
main() {
    detect_distro
    
    case $DISTRO in
        arch|manjaro|endeavouros)
            install_arch
            ;;
        debian|ubuntu|linuxmint|pop|kali)
            install_debian
            ;;
        fedora|rhel|centos)
            install_fedora
            ;;
        opensuse|opensuse-tumbleweed|sles)
            install_opensuse
            ;;
        gentoo)
            install_gentoo
            ;;
        *)
            echo "Ваш дистрибутив ($DISTRO) не поддерживается или не распознан."
            echo "Попробуйте установить драйвера вручную."
            exit 1
            ;;
    esac
    
    # Общие действия для всех дистрибутивов
    echo "Перезагружаем сервисы NetworkManager..."
    systemctl restart NetworkManager
    
    echo "Обновляем initramfs..."
    if [ -f /etc/arch-release ]; then
        mkinitcpio -P
    elif [ -f /etc/debian_version ]; then
        update-initramfs -u
    elif [ -f /etc/fedora-release ]; then
        dracut --force
    fi
    
    echo "Установка драйверов завершена! Рекомендуется перезагрузить систему."
}

main
