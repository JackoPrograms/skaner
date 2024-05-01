#!/bin/bash

### Часть скрипта 2.1:
# Вызывается (из Часть скрипта 2) для сканирования конкретного поддомена на наличие файлов и папок
# ----------------------------------------------------------------------------



domain_ip_http_FUZZ=$1
name_file_out_ffuf=$2
domain_ip=$3


# переменная для хранения имя дерриктории запуска_процесса_сканирования
name_folder=`cat name_folder.txt`


# Вывод на экран информации о начале сканирования ffuf
ffuf_out_1="[...] ffuf запустил поиск для адреса: "
ffuf_out_1+=$domain_ip_http_FUZZ
echo $ffuf_out_1


ffuf -s -w big.txt -u $domain_ip_http_FUZZ -o $name_file_out_ffuf > /dev/null
# echo "З А Г Л У Ш К А" >> $name_file_out_ffuf
# Вызов скрипта совершающего запись в БД
python3 recording_ffuf.py $domain_ip $name_file_out_ffuf &


# Вывод в терминал сообщения об окончании сканирования конкретного поддомена
ffuf_out_2="[ + ] ffuf закончил работу для адреса: "
ffuf_out_2+=$domain_ip_http_FUZZ
echo $ffuf_out_2

wait