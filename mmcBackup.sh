#!/bin/bash
#
#
###################################################################################################################################
#
# Setup 
#
# Bailout if the is any uncaught error
set -e

logfile=/var/log/mmcbackup.log

exec 6>&1 7>&2
exec >$logfile 2>&1

dev=/dev/mmcblk0
ofmount=/tmp/mount.$$
. ./mountusb

backupdate=$(date +"%y-%m-%d_%H%M%S")
backup_folder=${ofmount}/mmcBackups
backupname=${backup_folder}/mmcBackup.${backupdate}.img.xz
backuptestfile=${backup_folder}/testfile.$$
keep=4

blksize=100
blkcount=$(fdisk -l ${dev}|grep ${dev}p1|awk -v blksize=${blksize} -e '
function ceil(x)
{y=int(x); return(x>y?y+1:y)} 	
{
FS=" ";
sec=$3;
print(ceil(sec/2/1024/blksize)+1);
}')


progs()
{
	action=${1:=start}
	for prog in mysql pihole-FTL lighttpd  lightdm
	do
		systemctl ${action} $prog && { echo "${action} $prog successful"; } || { echo "${action} $prog failed" ; exit 20; }
	done
}
#
# Setup done
#
###################################################################################################################################
	

###################################################################################################################################
#
# Safety check
#
###################################################################################################################################
[ ${blkcount} -lt 10 ] && exit 2

###################################################################################################################################
#
# Mount stick
#
###################################################################################################################################
mountusb  ${ofmount} || { echo "Stick cannot be mounted"; exit 3; }

###################################################################################################################################
#
# test if destination is writable
#
###################################################################################################################################
mkdir ${backup_folder} 1>/dev/null 2>&1 || true
touch ${backuptestfile} || { echo "cannot touch ${backuptestfile}"; exit 4; }
rm ${backuptestfile} || { echo "cannot delete ${backuptestfile}"; exit 5; }

###################################################################################################################################
#
# If there are more than ${keep} backup then delete backups older than 80 days
#
###################################################################################################################################
filecount=$(find ${backup_folder} -maxdepth 1 -type f | wc -l)
[ ${filecount} -gt ${keep} ] && find ${backup_folder} -maxdepth 1 -type f -mtime +80 -delete 

###################################################################################################################################
#
#  stop some programs
#
###################################################################################################################################
progs stop

###################################################################################################################################
#
#  write /var/log to disk
#
###################################################################################################################################
/usr/lib/armbian/armbian-ramlog write

###################################################################################################################################
#
#  copy source with dd to USB Stick
#
###################################################################################################################################
echo "${blkcount} blocks of ${blksize}M will be copied from ${dev} to ${backupname}"
dd if=${dev}  bs=${blksize}M count=${blkcount} | xz -1  -T0 >${backupname}
sync
echo -e "\nBackup done\n\ncontent of ${backup_folder}:"
ls -l ${backup_folder} 
sync

###################################################################################################################################
#
# Cleanup (unmount, restart stopped services, reset filedescriptors
#
###################################################################################################################################
umountusb ${ofmount} || echo -e "\numount of ${ofmount} FAILED"
progs start
# (Not needed, cause the machine is rebooted)
#
exec 1>&6 2>&7 6>&- 7>&-

sendlog $0 $logfile

###################################################################################################################################
#
#  write /var/log to disk
#
###################################################################################################################################
/usr/lib/armbian/armbian-ramlog write


shutdown -r now 

