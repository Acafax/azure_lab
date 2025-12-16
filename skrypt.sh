#update systemu
# zainstalowanie lvm2
# zrobienie PV
# wykonanie wspólnej VG
# wywołanie lv
# partycjonowanie lv na mirroring i spriping
# montowanie dysków do VM
# formatowanie dysków
# testowanie zapisu
# testowani odczytu

echo "--------------------------------------------"
echo "[1/11] update systemu i instalacja lvm2"
sudo apt-update
sudo apt-get install -y lvm2 > /dev/null 2>&1


echo "--------------------------------------------"
echo "[2/11] tworzenie dysków fizycznych"
sudo pvcreate -ff -y /dev/sdc /dev/sdd /dev/sde > dev/null 2>&1# nowe dyski c d e

echo "--------------------------------------------"
echo "[3/11] tworzenie VG z dysków"
sudo vgcreate data_vg /dev/sdc /dev/sdd /dev/sde > dev/null 2>&1

echo "--------------------------------------------"
echo "[4/11] tworzenie LV mirror"
sudo lvcreate --type raid1 -n lv_mirror -L 2G -m1 > dev/null 2>&1

echo "--------------------------------------------"
echo "[5/11] tworzenie lv Stripe"
sudo lvcreate -n lv_stripe -L 6G -i3 > /dev/null 2>&1


echo "--------------------------------------------"
echo "[6/11] formatowanie dysków"
sudo mkfx.ext4 /dev/data_vg/lv_mirror
sudo mkfs.ext4 -ff -y /dev/data_vg/lv_stripe

echo "--------------------------------------------"
echo "[8/11] Montowanie dysków"
sudo mkdir -p /dev/mnt
sudo mkdir -p /dev/mnt

sudo mount /dev/mnt /dev/data_vg/lv_mirror
sudo mount /dev/mnt /dev/data_vg/lv_stripe

echo "--------------------------------------------"
echo "[9/11] testowanie zapisy do lv_mirror"
sudo dd if=/dev/zero of=/dev/mnt/mirror/testfile -bs=1GB count=1 oflag=direct

echo "--------------------------------------------"
echo "[10/11] testowanie zapisy do lv_stripe"
sudo dd if=/dev/zero of=/dev/mnt/stripe/testfile -bs=1GB count=1 oflag=direct

echo "--------------------------------------------"
echo "[11/11] testowanie odczytu z lv_mirror"
sudo dd if=/dev/mnt/mirror/testfile of=/dev/null -bs=1GB count=1 oflag=direst

echo "--------------------------------------------"
echo "[10/11] testowanie odczytu z lv_stripe"
sudo dd if=/dev/mnt/stripe/testfile of=/dev/null -bs=1GB count=1 oflag=direst
