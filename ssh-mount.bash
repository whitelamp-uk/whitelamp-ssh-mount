
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
remDir="$1"
mntDir="$2"
here="$(dirname "$(realpath $0)")"



# Explain
if [ ! "$2" ]
then
    echo "Usage:"
    echo "  /bin/bash $0 remote_host:/path/ /mnt/directory [port default 22] [timeout_secs default=10, 0=keep trying forever]"
    echo "Example mount point:"
    echo "  mkdir $HOME/myremote"
    echo "Example crontab entries:"
    echo "  @reboot    $USER  /bin/bash  $here/ssh-mount.bash  $USER@myremote:/  $HOME/myremote  > $HOME/sshfs-mount.myremote.log 2>&1"
    echo "  * * * * *  $USER  /bin/bash  $here/ssh-mount.bash  $USER@myremote:/  $HOME/myremote  > $HOME/sshfs-mount.myremote.log 2>&1"
    exit
fi
port="$3"
if [ ! "$port" ]
then
    port="22"
fi
host="$(echo $remDir | tr '@' ' ' | tr ':' ' ' | awk '{print $2;}')"
toSecs="$4"
if [ ! "$toSecs" ]
then
    toSecs="10"
fi



# Get started
echo "$0 started"
date '+%Y-%m-%dT%H:%M:%S'



# Check if already mounted
if [ $(ls -la $mntDir | grep -v '^total' | grep -vE '\s\.\.?$' | wc -l) != 0 ]
then
    date '+%Y-%m-%dT%H:%M:%S'
    echo "$0 found things in $mntDir, no action needed"
    exit
fi



# Wait for a network connection
date '+%Y-%m-%dT%H:%M:%S'
echo -n "$0 waiting for test connection to $host .."
i=0
while [ 1 ]
do
    echo -n "."
    i=$((i+1))
    if [ "$(echo "$(nc -zv $host $port 2>&1)" | grep succeeded)" ]
    then
        echo -n " "
        date '+%Y-%m-%dT%H:%M:%S'
        echo "Successfully connected to $host"
        break;
    fi
    if [ "$i" = "$toSecs" ]
    then
        echo -n " "
        date '+%Y-%m-%dT%H:%M:%S'
        echo "* $0 timed out on test connection to $host"
        exit
    fi
    sleep 1
done



# Mount SSHFS
now=$(date '+%Y-%m-%dT%H:%M:%S')
sshfs $remDir $mntDir
err=$?



# Finish up
echo $now
if [ $err = 0 ]
then
    echo "* $0 mounted $remDir to $mntDir"
else
    echo "* $0 failed to mount $remDir to $mntDir [sshfs exit code $err]"
fi


