
idFile="$1"
remDir="$2"
mntDir="$3"
if [ ! "$3" ]
then
    echo "Usage:"
    echo "/bin/bash $0 pub_key_file remote_host:/path/ /mnt/directory [port def 22] [timeout_secs def 60, 0 = keep trying forever]"
    echo "Example cron entry:"
    echo "@reboot /bin/bash /root/whitelamp-ssh-mount/sshfs-mount.bash /home/mark/.ssh/id_rsa mark@snowy:/ /mnt/snowy > /var/log/sshfs-mount.last.log 2>&1"
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


# Wait for file system
#while [ ! -d /var/log ]
#do
#    sleep 1
#done
#echo -n "$0 file system ready: " >> $log
#date '+%Y-%m-%dT%H:%M:%S' >> $log


# Wait for a network connection
echo -n "$0 waiting for test connection to $host - "
date '+%Y-%m-%dT%H:%M:%S'
i=0
while [ 1 ]
do
    i=$((i+1))
    if [ "$(echo "$(nc -zv $host $port 2>&1)" | grep succeeded)" ]
    then
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
sudo sshfs -o allow_other,IdentityFile=$idFile $remDir $mntDir

# Report
if [ $? = 0 ]
then
    notify-send -t 4000 "$0 mounted $remDir to $mntDir"
    echo -n "$0 mounted $remDir to $mntDir - "
else
    notify-send -t 4000 "$0 failed to mount $remDir to $mntDir"
    echo -n "$0 failed to mount $remDir to $mntDir - "
fi
date '+%Y-%m-%dT%H:%M:%S'


