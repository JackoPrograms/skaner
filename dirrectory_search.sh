#!/bin/bash

### Часть скрипта 2:
# Ищем дерриетории и файлы на найденных поддоменах и ip-адресах. Переберает все поддомены и вызывает скрипт 2.1. для сканирования каждого поддомена.
# ----------------------------------------------------------------------------



# переменная для хранения имя дерриктории запуска_процесса_сканирования
name_folder=`cat name_folder.txt`
mkdir $name_folder/inf/ffuf_out

while IFS= read -r domain_ip || [[ -n $domain_ip ]]; do
    domain_ip_http_FUZZ="http://"
    domain_ip_http_FUZZ+=$domain_ip
    domain_ip_http_FUZZ+="/FUZZ"
    name_file_out_ffuf="./"
    name_file_out_ffuf+=$name_folder
    name_file_out_ffuf+="/inf/ffuf_out/"
    name_file_out_ffuf+=$domain_ip
    name_file_out_ffuf+="_ffuf_out.txt"
    bash ffuf_scan_domin-ip.sh $domain_ip_http_FUZZ $name_file_out_ffuf $domain_ip &
done < "./$name_folder/inf/domain_ip.txt"

wait