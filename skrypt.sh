#!/bin/bash
# A. Instalacja (wyciszona)
echo '>>> [1/7] Aktualizacja i instalacja LVM...'
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y lvm2 > /dev/null 2>&1

# B. Inicjalizacja Dysków Fizycznych (PV)
# -ff -y aby nie było błędu jezeli zostaną stare partycje
echo '>>> [2/7] Tworzenie Physical Volumes...'
sudo pvcreate -ff -y /dev/sdc /dev/sdd /dev/sde > /dev/null

# C. Tworzenie Grupy (VG)
echo '>>> [3/7] Tworzenie Volume Group (data_vg)...'
sudo vgcreate data_vg /dev/sdc /dev/sdd /dev/sde > /dev/null

# D. Tworzenie Woluminów Logicznych (LV) - RÓWNOLEGLE
echo '>>> [4/7] Tworzenie LV: Linear, Striped, Mirror...'

# 1. LINEAR (5GB) - bierze po kolei
echo '>>> [5/7] Tworzenie LV: Linear, Striped, Mirror...'
sudo lvcreate -n lv_linear -L 5G data_vg > /dev/null

# 2. STRIPED (6GB) - paski na 3 dyskach (stąd -i 3)
echo '>>> [6/7] Tworzenie LV: Linear, Striped, Mirror...'
sudo lvcreate -n lv_striped -L 6G -i 3 data_vg > /dev/null

# 3. MIRROR (2GB danych) - kopia 1:1 (wymaga 4GB miejsca fizycznego)
echo '>>> [7/7] Tworzenie LV: Mirror'
sudo lvcreate --type raid1 -n lv_mirror -L 2G -m 1 data_vg > /dev/null

# E. Formatowanie i Montowanie
sudo mkfs.ext4 /dev/data_vg/lv_linear > /dev/null 2>&1
sudo mkfs.ext4 /dev/data_vg/lv_striped > /dev/null 2>&1
sudo mkfs.ext4 /dev/data_vg/lv_mirror > /dev/null 2>&1

sudo mkdir -p /mnt/linear /mnt/striped /mnt/mirror
sudo mount /dev/data_vg/lv_linear /mnt/linear
sudo mount /dev/data_vg/lv_striped /mnt/striped
sudo mount /dev/data_vg/lv_mirror /mnt/mirror

# F. TESTY WYDAJNOŚCI (dd)
echo ' '
echo '================= WYNIKI TESTÓW WYDAJNOŚCI ================='

echo -n '1. LINEAR WRITE:  '
sudo dd if=/dev/zero of=/mnt/linear/testfile bs=1G count=1 oflag=direct 2>&1 | grep -o '[0-9.]* MB/s'

echo -n '2. MIRROR WRITE:  '
sudo dd if=/dev/zero of=/mnt/mirror/testfile bs=1G count=1 oflag=direct 2>&1 | grep -o '[0-9.]* MB/s'

echo -n '3. STRIPED WRITE: '
sudo dd if=/dev/zero of=/mnt/striped/testfile bs=1G count=1 oflag=direct 2>&1 | grep -o '[0-9.]* MB/s'

echo '============================================================'
