INITIAL_ISO_PATH=$1
FINAL_ISO_PATH=$2

IGNITION_PATH=$3
ROOTFS_PATH=$4
KERNEL_ARGUMENTS=$5

CONFIG_PATH=$(dirname "$0")

if [ -z "$1" ]
  then
    echo "Please provide the initial ISO"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Please provide the path for final ISO"
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Please provide the url for ignition"
    exit 1
fi

if [ -z "$4" ]
  then
    echo "Please provide the url for rootfs"
    exit 1
fi

if [ -z "$5" ]
  then
    echo "Please provide the kernel arguments"
    exit 1
fi

echo "***** WARNING: this script needs to be executed as root *********"

# create initial directories
umount /mnt/custom_live_iso
rm -rf /mnt/custom_live_iso
mkdir /mnt/custom_live_iso

rm -rf /tmp/modified_iso
mkdir /tmp/modified_iso
chown 777 /tmp/modified_iso

# mount the installer iso
echo "mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso"
mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso

# copy to a temporary directory
pushd /mnt/custom_live_iso
tar cf - . | (cd /tmp/modified_iso && tar xfp -)
popd

# generate the extra ramdisk
#bash $CONFIG_PATH/ramdisk_generator.sh $IGNITION_PATH /tmp/modified_iso/coreos/ignition_ramdisk

# append parameter to isolinux.cfg
sed -i "\|^APPEND|s|$| ignition.firstboot ignition.platform.id=metal ignition.config.url=${IGNITION_PATH} coreos.live.rootfs_url=${ROOTFS_PATH} $KERNEL_ARGUMENTS|" /tmp/modified_iso/syslinux/isolinux.cfg

# rebuild ISO
pushd /tmp/modified_iso
mkisofs -v -l -r -J -o $FINAL_ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
popd

# clean
umount /mnt/custom_live_iso
rm -rf /mnt/custom_live_iso
rm -rf /tmp/modified_iso

