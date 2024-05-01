#!/bin/bash

### Часть скрипта 4:
# Сканируем открытые порты на версии ОС и ПО с помощью nmap
# ----------------------------------------------------------------------------



# Создаем массив для хранения PID процессов nmap и файлов доменов
declare -a pids
declare -a files
# переменная для хранения имя дерриктории запуска_процесса_сканирования
name_folder=`cat name_folder.txt`

# Функция для проверки завершения процесса сканирования
function check_nmap_process {
    if ! ps -p $1 &> /dev/null; then
        name_file=$2
        echo "--------------------------Имя файла 2: $name_file"
        python3 recording_OS-PO_BD.py $name_file
        echo "--------------------------Имя файла 3: $name_file"
    fi
}


# Функция для запуска сканирования домена и сохранения PID процесса в массив
function scan_domain {
    domain_ip=$1
    ports=""
    i=0
    
    # Разделение строки на ip и port (Читаем из файла номер открытых портов для проверяемого ip, которое
    # записано в domain_ip)
    while IFS= read -r line; do
    	IFS=':' read -r ip port <<< "$line"
    	if [ "$ip" == "$domain_ip" ]; then
    	    i+=1
    	    if ((i != 1)); then
    	        ports+=","
    	    fi
    	    ports+=$port
    	  
    	fi
    done < "./$name_folder/inf/sort_nmap_out_kopiya_ip_ports.txt"
    
    # echo "======== Порты: " $ports
    
    # Запускаем процесс сканирования на найденых открытых портах для нашего ip, (переменные port и domain_ip)
    mkdir $name_folder/worker/version_OS-PO
    local file="OS-PO_$domain_ip.txt"
    nmap -Pn -sS -A -p $ports $domain_ip > $name_folder/worker/version_OS-PO/$file &
    # nmap -oN $name_folder/worker/version_OS-PO/$file -Pn -sS -A -p $ports $domain_ip &
    pid=$!
    pids+=($pid)
    files+=("$file")
}


# Считываем ip из файла subfinder_out.txt и запускаем сканирование для каждого ip
echo "[...] запускается nmap (определяет версии ОС и ПО)"

while IFS= read -r domain_ip || [[ -n $domain_ip ]]; do
    scan_domain "$domain_ip"
done < "./$name_folder/inf/sort_nslookup_out_ip.txt"


# Ожидание завершения всех процессов сканирования и вывод результатов для каждого домена
for ((i=0; i<${#pids[@]}; i++)); do
    wait ${pids[$i]}
    check_nmap_process ${pids[$i]} "${files[$i]}"
    # echo "===========" ${pids[$i]} "${files[$i]}"
done


wait
echo "[ + ] nmap - закончил работу по поиску версий ОС и ПО"
