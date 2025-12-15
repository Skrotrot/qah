DEVICE='--dest-device /dev/nvme0n1'
IGNITION='--dest-ignition qah.ign'
docker run --security-opt label=disable --pull=always --rm -v .:/data -w /data \
    quay.io/coreos/coreos-installer:release iso customize $DEVICE $IGNITION \
    -o qah.iso fedora-coreos-43.20251110.3.1-live-iso.x86_64.iso