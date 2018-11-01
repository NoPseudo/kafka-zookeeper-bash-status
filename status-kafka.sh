#!/bin/bash

script_name="status_kafka"

############################
#
# Auteur      : Martineau Benjamin
# Date        : 08/09/2018
# Version     : 1
# Revision    : 0
# Description : Script Récupération Status Kafka Nodes
# Execution   : ./$script_name
#
#############################

############################# Déclaration des variables d'environement #############################
DATE_START=`date +%H:%M:%S`
DATE=$(date +"%Y.%M.%d.%h.%m")
LOG_FILE="confluent-status-$DATE.log"

KAFKA_ZOO_SERVER_1=""
KAFKA_ZOO_SERVER_2=""
KAFKA_ZOO_SERVER_3=""

KAKFA_ZOO_PORTS="2181"
#KAFKA_JMX_PORTS="9999"

USERNAME_SSH=""
PASSWORD_SSH=""

PING_SERVER_1=$(ping -qc1 ${KAFKA_ZOO_SERVER_1} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"FAIL") }')
PING_SERVER_2=$(ping -qc1 ${KAFKA_ZOO_SERVER_2} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"FAIL") }')
PING_SERVER_3=$(ping -qc1 ${KAFKA_ZOO_SERVER_3} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"FAIL") }') 

KAFKA_ZOO_SERVICE_1=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_1} "systemctl status confluent-zookeeper-instance-01.service | grep -c 'active (running)'")
KAFKA_ZOO_SERVICE_2=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_2} "systemctl status confluent-zookeeper-instance-01.service | grep -c 'active (running)'")
KAFKA_ZOO_SERVICE_3=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_3} "systemctl status confluent-zookeeper-instance-01.service | grep -c 'active (running)'")

KAFKA_ZOO_PORT_SERVER_1=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_1} "netstat -tpnl | grep -c ':2181'")
KAFKA_ZOO_PORT_SERVER_2=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_2} "netstat -tpnl | grep -c ':2181'")
KAFKA_ZOO_PORT_SERVER_3=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_3} "netstat -tpnl | grep -c ':2181'")

KAFKA_ZOO_LEADER_1=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_1} "netstat -tpnl | grep -c ':2888'")
KAFKA_ZOO_LEADER_2=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_2} "netstat -tpnl | grep -c ':2888'")
KAFKA_ZOO_LEADER_3=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_3} "netstat -tpnl | grep -c ':2888'")

KAFKA_ZOO_FOLLOWER_1=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_1} "netstat -tpnl | grep -c ':3888'")
KAFKA_ZOO_FOLLOWER_2=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_2} "netstat -tpnl | grep -c ':3888'")
KAFKA_ZOO_FOLLOWER_3=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_3} "netstat -tpnl | grep -c ':3888'")

KAFKA_IP_SERVER_1=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_1} "hostname -i")
KAFKA_IP_SERVER_2=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_2} "hostname -i")
KAFKA_IP_SERVER_3=$(sshpass -p '${PASSWORD_SSH}' ssh -o StrictHostKeyChecking=no ${USERNAME_SSH}@${KAFKA_ZOO_SERVER_3} "hostname -i")

############################# Fin Déclaration des variables d'environement #########################

############################# Les serveurs sont t-ils en ligne ? ###################################
echo -e "*-------------------------------------------------------------------*"
G_PING_SERVER_1=$(echo $PING_SERVER_1 | grep -c "OK")
G_PING_SERVER_2=$(echo $PING_SERVER_2 | grep -c "OK")
G_PING_SERVER_3=$(echo $PING_SERVER_3 | grep -c "OK")

if [ $G_PING_SERVER_1 == "1" ] && [ $G_PING_SERVER_2 == "1" ] && [ $G_PING_SERVER_3 == "1" ]; then
	PING_ALL="1"
	echo -e "* [STATUS] Tous les serveurs Kafka sont en ligne."
else
	PING_ALL="0"
	echo -e "* [STATUS] Tous les seveurs Kafka ne sont pas en ligne :"
	echo -e "* [STATUS] Serveur 1 : ${PING_SERVER_1} "
	echo -e "* [STATUS] Serveur 2 : ${PING_SERVER_2} "
	echo -e "* [STATUS] Serveur 3 : ${PING_SERVER_3} "
fi
echo -e "*-------------------------------------------------------------------*"
############################# Fin Les serveurs sont t-ils en ligne ? ###############################

############################# Les services ZooKeePer sont t-ils démarrés ? #########################
echo -e "*-------------------------------------------------------------------*"
if [ ${PING_ALL} == "1" ]; then
	if [ ${KAFKA_ZOO_SERVICE_1} == "1" ] && [ ${KAFKA_ZOO_SERVICE_2} == "1" ] && [ ${KAFKA_ZOO_SERVICE_3} == "1" ]; then
		echo -e "* [STATUS] Tous les services ZooKeePer sont démarrés."
		KZS_1="Running"
		KZS_2="Running"
		KZS_3="Running"
	else
		echo -e "* [STATUS] Tous les services ZooKeePer ne sont pas tous démarrés :"
		if [ ${KAFKA_ZOO_SERVICE_1} == "0" ];then
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_SERVICE_1} - FAIL "
			KZS_1="Stopped"
		else
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_SERVICE_1} - OK "
			KZS_1="Running"
		fi
		if [ ${KAFKA_ZOO_SERVICE_2} == "0" ];then
			echo -e "* [STATUS] Serveur 2 : ${KAFKA_ZOO_SERVICE_2} - FAIL "
			KZS_2="Stopped"
		else
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_SERVICE_2} - OK "
			KZS_2="Running"
		fi
		if [ ${KAFKA_ZOO_SERVICE_3} == "0" ];then
			echo -e "* [STATUS] Serveur 3 : ${KAFKA_ZOO_SERVICE_3} - FAIL "
			KZS_3="Stopped"
		else
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_SERVICE_3} - OK "
			KZS_3="Running" 
		fi
	fi
else
	echo -e "* [STATUS] Tous les seveurs Kafka ne sont pas en ligne :"
	echo -e "* [STATUS] Les conditions n'étant pas remplis, arrêt du script."
	exit 1
fi
echo -e "*-------------------------------------------------------------------*"
############################# Fin Les services ZooKeePer sont t-ils démarrés ? #####################

############################# Les ports ZooKeePer écoutent t-ils bien ? ############################
echo -e "*-------------------------------------------------------------------*"
if [ ${PING_ALL} == "1" ]; then
	if [ ${KAFKA_ZOO_PORT_SERVER_1} == "1" ] && [ ${KAFKA_ZOO_PORT_SERVER_2} == "1" ] && [ ${KAFKA_ZOO_PORT_SERVER_2} == "1" ]; then
		echo -e "* [STATUS] Tous les services ZooKeePer écoutent bien sur le port 2181."
	else
		echo -e "* [STATUS] Tous les services ZooKeePer n'écoutent pas tous sur le ports 2181 :"
		if [ ${KAFKA_ZOO_PORT_SERVER_1} == "0" ];then
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_PORT_SERVER_1} - FAIL "
		else
			echo -e "* [STATUS] Serveur 1 : ${KAFKA_ZOO_PORT_SERVER_1} - OK "
		fi
		if [ ${KAFKA_ZOO_PORT_SERVER_2} == "0" ];then
			echo -e "* [STATUS] Serveur 2 : ${KAFKA_ZOO_PORT_SERVER_2} - FAIL "
		else
			echo -e "* [STATUS] Serveur 2 : ${KAFKA_ZOO_PORT_SERVER_2} - OK "
		fi
		if [ ${KAFKA_ZOO_PORT_SERVER_3} == "0" ];then
			echo -e "* [STATUS] Serveur 3 : ${KAFKA_ZOO_PORT_SERVER_3} - FAIL "
		else
			echo -e "* [STATUS] Serveur 3 : ${KAFKA_ZOO_PORT_SERVER_3} - OK "
		fi
	fi
else
	echo -e "* [STATUS] Tous les seveurs Kafka ne sont pas en ligne :"
	echo -e "* [STATUS] Les conditions n'étant pas remplis, arrêt du script."
	exit 1
fi
echo -e "*-------------------------------------------------------------------*"
############################# Fin Les ports ZooKeePer écoutent t-ils bien ? ########################

############################# Quel node ZooKeePer est LEADER du Cluster ? ##########################
echo -e "*-------------------------------------------------------------------*"
if [ ${PING_ALL} == "1" ]; then
	case ${KAFKA_ZOO_LEADER_1} in
		1)
			echo -e "* [STATUS] LEADER     : ${KAFKA_ZOO_SERVER_1}"
			KZLS_1="YES"
			;;
		0)
			echo -e "* [STATUS] NOT LEADER : ${KAFKA_ZOO_SERVER_1}"
			KZLS_1="NOT"
			;;
	esac
	case ${KAFKA_ZOO_LEADER_2} in
		1)
			echo -e "* [STATUS] LEADER     : ${KAFKA_ZOO_SERVER_2}"
			KZLS_2="YES"
			;;
		0)
			echo -e "* [STATUS] NOT LEADER : ${KAFKA_ZOO_SERVER_2}"
			KZLS_2="NOT"
			;;
	esac
	case ${KAFKA_ZOO_LEADER_3} in
		1)
			echo -e "* [STATUS] LEADER     : ${KAFKA_ZOO_SERVER_3}"
			KZLS_3="YES"
			;;
		0)
			echo -e "* [STATUS] NOT LEADER : ${KAFKA_ZOO_SERVER_3}"
			KZLS_3="NOT"
			;;
	esac
else
	echo -e "* [STATUS] Tous les seveurs Kafka ne sont pas en ligne :"
	echo -e "* [STATUS] Les conditions n'étant pas remplis, arrêt du script."
	exit 1
fi
echo -e "*-------------------------------------------------------------------*"
############################# Fin Quel node ZooKeePer est LEADER du Cluster ? ######################

############################# Quel node ZooKeePer est FOLLOWER du Cluster ? ########################
echo -e "*-------------------------------------------------------------------*"
if [ ${PING_ALL} == "1" ]; then
	case ${KAFKA_ZOO_FOLLOWER_1} in
		1)
			echo -e "* [STATUS] FOLLOWER     : ${KAFKA_ZOO_SERVER_1}"
			KZF_1="YES"
			;;
		0)
			echo -e "* [STATUS] NOT FOLLOWER : ${KAFKA_ZOO_SERVER_1}"
			KZF_1="NOT"
			;;
	esac
	case ${KAFKA_ZOO_FOLLOWER_2} in
		1)
			echo -e "* [STATUS] FOLLOWER     : ${KAFKA_ZOO_SERVER_2}"
			KZF_2="YES"
			;;
		0)
			echo -e "* [STATUS] NOT FOLLOWER : ${KAFKA_ZOO_SERVER_2}"
			KZF_2="NOT"
			;;
	esac
	case ${KAFKA_ZOO_FOLLOWER_3} in
		1)
			echo -e "* [STATUS] FOLLOWER     : ${KAFKA_ZOO_SERVER_3}"
			KZF_3="YES"
			;;
		0)
			echo -e "* [STATUS] NOT FOLLOWER : ${KAFKA_ZOO_SERVER_3}"
			KZF_3="NOT"
			;;
	esac
else
	echo -e "* [STATUS] Tous les seveurs Kafka ne sont pas en ligne :"
	echo -e "* [STATUS] Les conditions n'étant pas remplis, arrêt du script."
	exit 1
fi
echo -e "*-------------------------------------------------------------------*"

############################# Fin Quel node ZooKeePer est FOLLOWER du Cluster ? ####################

############################# Informations sur le Cluster ##########################################

echo -e "*----------------------------------------------------------------------------------------------------------------*"
echo -e "* |   Serveur IP  |            Serveur FQDN            |     Ping    |    ZooKeePer    |    Leader   | Follower |"
echo -e "* |---------------|------------------------------------|-------------|-----------------|-------------|----------|"
echo -e "* | ${KAFKA_IP_SERVER_1} | ${KAFKA_ZOO_SERVER_1}  | ${PING_SERVER_1} |     ${KZS_1}     |     ${KZLS_1}     |    ${KZF_1}   |"
echo -e "* | ${KAFKA_IP_SERVER_2} | ${KAFKA_ZOO_SERVER_2}  | ${PING_SERVER_2} |     ${KZS_2}     |     ${KZLS_2}     |    ${KZF_2}   |"
echo -e "* | ${KAFKA_IP_SERVER_3} | ${KAFKA_ZOO_SERVER_3}  | ${PING_SERVER_3} |     ${KZS_3}     |     ${KZLS_3}     |    ${KZF_3}   |"
echo -e "*----------------------------------------------------------------------------------------------------------------*"

############################# Fin Informations sur le Cluster ######################################
DATE_END=`date +%H:%M:%S`

echo -e "*-------------------------------------------------------------------*"
echo -e "* Début : ${DATE_START} 				      Fin : ${DATE_END}"                                              
echo -e "*-------------------------------------------------------------------*"
