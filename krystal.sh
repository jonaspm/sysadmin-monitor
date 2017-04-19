#!/bin/bash
#autorjonaspm
#Fecha: Tue Apr 11 12:30:19 MDT 2017
#Comentario: Programa de monitoreo

config="krystal.conf"
list=$(tail -n+2 <(tac $config))

clear
commands[0]='df --total | grep total | awk '"'"'{print $5/1}'"'"
commands[1]='uptime | awk '"'"'{print $4}'"'"
commands[2]='uptime | awk '"'"'{print ($5+$6+$7)/3/$(getconf _NPROCESSORS_ONLN)}'"'"
commands[3]='free --total | grep Total | awk '"'"'{print $3/$2*100}'"'"


echo "n" | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""

while IFS=, read -r ip usuario contrasena; do
	conexion="$usuario@$ip"
	ssh-keygen -R $ip > /dev/null
	ssh-keyscan $ip >> ~/.ssh/known_hosts
	./contrasena $conexion $contrasena 2> /dev/null
	mv ./backup ./backup.old 2> /dev/null
	for index in ${!commands[*]}; do
		ssh -n -T $conexion ${commands[$index]} >> ./backup
	done
	#DROPBOX
	rm ./backup.old
done << EOF
$list
EOF
correo=$(cat $config | tail -n1)

#echo "MENSAJE" | mailx -v -s "Asunto" $correo

exit 0
