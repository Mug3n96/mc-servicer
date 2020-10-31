#!/bin/bash

# env --

stopsec=300
stopmsg="Server wird in `expr 300 / 60` min runtergefahren!"

# env end --

# define servers here --

declare -A server0=(
  [path]="/home/gameservers/nelltopia2"
  [script]="./run.sh"
  [name]="nelltopia2"
  [description]="Nellis Minecraft Server"
)

declare -A server1=(
  [path]="/home/gameservers/egalmc"
  [script]="./run.sh"
  [name]="egalmc"
  [description]="Auch Nellis Minecraft Server"
)

declare -A server3=(
  [path]="/home/gameservers/trijana"
  [script]="./run.sh"
  [name]="trijana"
  [description]="Trians und Janas Server"
)

# define section end --

createService () {
  if [ -f "/etc/systemd/system/mc-$1.service" ]; then
    echo "mc-$1.service already exist!"
  else
    cat >/etc/systemd/system/mc-$1.service <<EOL
    [Unit]
    Description=$2
    After=network.target

    [Service]
    WorkingDirectory=$3

    User=gameadmin
    Group=gameadmin

    Restart=always

    ExecStart=/usr/bin/screen -DmS mc-$1 $4

    ExecStop=/usr/bin/screen -p 0 -S mc-$1 -X eval 'stuff "save-all"\015'
    ExecStop=/usr/bin/screen -p 0 -S mc-$1 -X eval 'stuff "stop"\015'

    [Install]
    WantedBy=multi-user.target
EOL
    echo "mc-$1.service created!"
  fi
}

enableService () {
  if [ -f "/etc/systemd/system/mc-$1.service" ]; then
    systemctl enable "mc-$1.service"
    echo "mc-$1.service enabled!"
  else
    echo "mc-$1.service does not exist!"
  fi
}

startService () {
  if [ -f "/etc/systemd/system/mc-$1.service" ]; then
    systemctl start "mc-$1.service"
    echo "mc-$1.service started!"
  else
    echo "mc-$1.service does not exist or not enabled!"
  fi
}

stopService () {
  if [ -f "/etc/systemd/system/mc-$1.service" ]; then
    while [ $stopsec -gt 0 ]; do
      local min=`expr $stopsec / 60`
      stopmsg=$(echo $stopmsg | sed -E "s/[0-9]+/$min/")
      echo $stopmsg
      echo "service is stopping in $stopsec seconds"
      sudo -u gameadmin screen -p 0 -S "mc-$1" -X stuff "say $stopmsg\n"
      sleep 60
      stopsec=$(($stopsec-60))
    done
    systemctl stop "mc-$1.service"
    echo "mc-$1.service stopped!"
  else
    echo "mc-$1.service does not exist or not enabled!"
  fi
}

listService () {
  if [ -f "/etc/systemd/system/mc-$1.service" ]; then
    var=$(systemctl status "mc-$1.service" | grep "Active: active")
    if [ -z "$var" ]; then
      echo "$1: stopped"
    else
      echo "$1: active"
    fi
  else
    echo "mc-$1.service does not exist! create the service first."
  fi
}

# $1=callback, $2=argument
iterateOverServers () {
  changed=0
	# cursor for iterating over server array
	declare -n server
  for server in ${!server@}; do
    if [ $2 == all ]; then
      # if the argument is "all" iterate over every object and call subroutine for each one
      $1 "${server[name]}" "${server[description]}" "${server[path]}" "${server[script]}"
      changed=1
    else 
      # if argument exist (and ist not "all") find specific server and call subroutine only for the specific one
      if [ ${server[name]} == $2 ]; then
        $1 "${server[name]}" "${server[description]}" "${server[path]}" "${server[script]}"
        changed=1
      fi
    fi
  done

  if [[ changed == 0 ]]; then
    echo "Server can't be found!"
  fi
}

# create service
if [[ $* == *-create* ]]; then
  iterateOverServers createService $1
fi

if [[ $* == *-enable* ]]; then
  iterateOverServers enableService $1
fi

if [[ $* == *-start* ]]; then
  iterateOverServers startService $1
fi

if [[ $* == *-stop* ]]; then
  iterateOverServers stopService $1
fi

if [[ $* == *-list* ]]; then
  iterateOverServers listService $1
fi
