# mmcBackup

## This is a small hack to create a backup for my SD-Card in my Cubox.

The partition is smaller than my SD-Card (64GB SD-Card with an 8GB partition). So a complete backup sector by sector will be 64GB and 56GB of these are useless. So I decided to write this script.
It calculates (with some saftey) how many blocks are needed, and write only these blocks to the backupfile.

You may ask: Why use a 8GB partition on a 64GB SD-Card? Well the SD-Card was just there and the applications don't need more space. Yes, I could use a 8GB SD-Card, but why should I? Having 56GB of spare blocks will prevent the SD-Card a long time from dying caused by worn out blocks. 

You may also ask: Why not useing a file based backup. The answer is shameful: I wasn't successful creating a bootable SD-Card and I really wanted to have a working backup. If you have any suggestions how to create a bootable SD-card with U-boot, please let me know!
