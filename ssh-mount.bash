
# Prevent more than one process at a time
ps="$(ps ax)"
found="$(echo "$ps" | grep "$(realpath "$0")" | grep -v "$match")"


if [ "$found" ]
then
    echo -n "$0 already running in another process - "
    date '+%Y-%m-%dT%H:%M:%S'
    exit
fi



# Configure
idFile="$1"
remDir="$2"
mntDir="$3"
if [ ! "$3" ]
then
    echo "Usage:"
    echo "/bin/bash $0 pub_key_file remote_host:/path/ /mnt/directory [port def 22] [timeout_secs def 60, 0 = keep trying forever]"
    echo "Example cron entries:"
    echo "@reboot    /bin/bash /root/whitelamp-ssh-mount/ssh-mount.bash /home/mark/.ssh/id_rsa mark@snowy:/ /mnt/snowy > /var/log/sshfs-mount.boot.log 2>&1"
    echo "* * * * *  /bin/bash /root/whitelamp-ssh-mount/ssh-mount.bash /home/mark/.ssh/id_rsa mark@snowy:/ /mnt/snowy > /var/log/sshfs-mount.minutely.log 2>&1"
    exit
fi
port="$4"
if [ ! "$port" ]
then
    port="22"
fi
host="$(echo $remDir | tr '@' ' ' | tr ':' ' ' | awk '{print $2;}')"
toSecs="$5"
if [ ! "$toSecs" ]
then
    toSecs="60"
fi



echo -n "$0 started - "
date '+%Y-%m-%dT%H:%M:%S'


# Check if already mounted
if [ $(ls -la $mntDir | grep -v '^total' | grep -vE '\s\.\.?$' | wc -l) != 0 ]
then
    notify-send -t 4000 "$0 found things in $mntDir, no action needed"
    echo -n "$0 found things in $mntDir, no action needed - "
    date '+%Y-%m-%dT%H:%M:%S'
    exit
fi



# Wait for a network connection
echo -n "$0 waiting for test connection to $host - "
date '+%Y-%m-%dT%H:%M:%S'
i=0
while [ 1 ]
do
    i=$((i+1))
    if [ "$(echo "$(nc -zv $host $port 2>&1)" | grep succeeded)" ]
    then
        echo -n "Successfully connected to $host - "
        date '+%Y-%m-%dT%H:%M:%S'
        break;
    fi
    if [ "$i" = "$toSecs" ]
    then
        notify-send -t 4000 "$0 timed out on test connection to $host"
        echo -n "$0 timed out on test connection to $host - "
        date '+%Y-%m-%dT%H:%M:%S'
        exit
    fi
    sleep 1
done



# Mount SSHFS
now=$(date '+%Y-%m-%dT%H:%M:%S')
sudo sshfs -o allow_other,IdentityFile=$idFile $remDir $mntDir
err=$?


# Report
if [ $err = 0 ]
then
    notify-send -t 4000 "$0 mounted $remDir to $mntDir"
    echo -n "$0 mounted $remDir to $mntDir - $now"
else
    notify-send -t 4000 "$0 failed to mount $remDir to $mntDir [sshfs exit code $err]"
    echo -n "$0 [sshfs exit code $err] failed to mount $remDir to $mntDir - $now"
    umount $mntDir
    echo "Unmounted for a clean mount next time
fi


