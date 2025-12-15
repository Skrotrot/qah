          #!/usr/bin/bash
          set -euxo pipefail

          NAME="${1:?missing unit base name}"
          PHASE1="/var/lib/${NAME}.phase1"
          STAMP="/var/lib/${NAME}.stamp"

          if [ ! -e "${PHASE1}" ]; then
            echo "== Phase 1/2: Docker repo, remove moby, install RPM Fusion (versioned release RPMs) =="

            curl --fail --silent --show-error \
              --output-dir "/etc/yum.repos.d" \
              --remote-name https://download.docker.com/linux/fedora/docker-ce.repo

            # Only remove if present (avoids failing on images where some pkgs aren’t installed)
            remove_pkgs=()
            for p in moby-engine containerd runc docker-cli; do
              rpm -q "$p" >/dev/null 2>&1 && remove_pkgs+=("$p") || true
            done
            if [ "${#remove_pkgs[@]}" -gt 0 ]; then
              rpm-ostree override remove "${remove_pkgs[@]}"
            fi

            FEDORA="$(rpm -E %fedora)"
            rpm-ostree install -y --allow-inactive \
              "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA}.noarch.rpm" \
              "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA}.noarch.rpm"

            touch "${PHASE1}"
            systemctl --no-block reboot
            exit 0
          fi

          echo "== Phase 2/2: swap RPM Fusion release pkgs, layer Xorg+i3+NVIDIA470xx, set kargs =="

          rpm-ostree update -y \
            --uninstall rpmfusion-free-release \
            --uninstall rpmfusion-nonfree-release \
            --install rpmfusion-free-release \
            --install rpmfusion-nonfree-release \
            --install docker-ce \
            --install NetworkManager-wifi \
            --install xorg-x11-server-Xorg \
            --install xorg-x11-xinit \
            --install xorg-x11-xauth \
            --install xrandr \
            --install xorg-x11-drv-libinput \
            --install i3 \
            --install i3status \
            --install i3lock \
            --install rofi \
            --install alacritty \
            --install maim \
            --install slop \
            --install xdotool \
            --install brightnessctl \
            --install pulseaudio-utils \
            --install libnotify \
            --install lxqt-policykit \
            --install polkit \
            --install libvirt-daemon-kvm \
            --install libvirt-daemon-config-network \
            --install qemu-kvm \
            --install virt-install \
            --install virt-manager \
            --install virt-viewer \
            --install virt-top \
            --install flatpak \
            --install p11-kit-server \
            --install libguestfs-tools \
            --install python3-libguestfs \
            --install spice-gtk \
            --install gcc \
            --install make \
            --install elfutils-libelf-devel \
            --install kernel-devel \
            --install akmod-nvidia-470xx \
            --install xorg-x11-drv-nvidia-470xx \
            --allow-inactive

          rpm-ostree kargs \
            --append-if-missing=rd.driver.blacklist=nouveau,nova_core \
            --append-if-missing=modprobe.blacklist=nouveau,nova_core \
            --append-if-missing=nvidia-drm.modeset=1

          touch "${STAMP}"
          systemctl --no-block reboot