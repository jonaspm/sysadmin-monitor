#!/bin/bash
#autorjonaspm
#Fecha: Tue Apr 11 12:30:19 MDT 2017
#Comentario: Programa de monitoreo

clear

app_name="sysadmin-monitor"
folder="/etc/cron.$app_name"
config="krystal.conf"
list=$(tail -n+3 <(tac $folder/$config))
correo=$(echo $(cat $folder/$config | tail -n2) | awk '{print $1}')
access_token=$(cat $folder/$config | tail -n1)

commands[0]='df --total | grep total | awk '"'"'{print $5/1}'"'"
commands[1]='users | tr '"' ' '\n' "'| sort -u | wc -l'
commands[2]='uptime | awk '"'"'{print ($8+$9+$10)*100/3/$(getconf _NPROCESSORS_ONLN)}'"'"
commands[3]='free --total | grep Total | awk '"'"'{print $3/$2*100}'"'"

textos[0]="Porcentaje de disco: "
textos[1]="Usuarios conectados: "
textos[2]="Porcentaje de carga del sistema: "
textos[3]="Porcentaje de uso de RAM: "

echo "n" | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""

while IFS=, read -r ip usuario contrasena; do
	mkdir ~/$app_name/$ip 2> /dev/null
	conexion="$usuario@$ip"
	ssh-keygen -R $ip > /dev/null
	ssh-keyscan $ip >> ~/.ssh/known_hosts
	$folder/exp_copy_id $conexion $contrasena 2> /dev/null
	mv ~/$app_name/$ip/$usuario ~/$app_name/$ip/$usuario.old 2> /dev/null
	for index in ${!commands[*]}; do
		resultado=$(ssh -n -T $conexion ${commands[$index]})
		mensaje=$(echo ${textos[$index]} $resultado)
		if [[ $(bc <<< "$resultado > 70") > 0 ]] && [[ $index -ne 1 ]]; then
			printf $mensaje | mailx -v -s "Exceso de uso de recursos" $correo
		fi
		echo $mensaje >> ~/$app_name/$ip/$usuario
	done
	curl -X POST https://content.dropboxapi.com/2/files/upload --header "Authorization: Bearer $access_token" --header "Dropbox-API-Arg: {\"path\": \"/$ip/$usuario.txt\",\"mode\":\"add\",\"autorename\": true,\"mute\": false}" --header "Content-Type: application/octet-stream" --data-binary "@$(printf ~/$app_name/$ip/$usuario)"
	rm ~/$app_name/$ip/$usuario.old
done << EOF
$list
EOF
exit 0
