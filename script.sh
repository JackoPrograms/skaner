#!/bin/bash

### Часть скрипта 1:
# 1  - Сбор поддоменов и добавление сканируемого домена в этот же список
# 2  - Собераемм ip-адреса для найденного списка поддоменов
# 3  - Сбор списка открытых портов на найденых ip
# ----------------------------------------------------------------------------



# Cчитываем имя домена из файла
domen=`cat ./automated_scanning/domain_name.txt`

# Создаём папку для текущего запуска
now=$(date +"%d-%m-%Y_%H-%M-%S")
r="_"
name_folder="$now$r$domen"
mkdir $name_folder
mkdir $name_folder/inf
mkdir $name_folder/worker



while getopts "x d s" ARG; do
  case "$ARG" in 
    d) dom="Yes";; # Флаг nmap - для сканирования поддоменов
    :​) echo "аргумент отсутствует";;
    \?) echo "Что-то не так";;
  esac
done

# Записываем имя рабочей папки в файл
echo "$name_folder" > name_folder.txt



###-1 Запускаем subfinder и сохраняем результат работы в файл:
echo "[...] запускается subfinder"
echo "------------------- Результаты -------------------"

subfinder -d $domen > ./$name_folder/inf/subfinder_out.txt

echo "--------------------------------------------------"

# Записываем собранные поддомены в таблицу БД
python3 recording_sub_domains.py &

# Добавляем сканируемый домен
echo $domen >> ./$name_folder/inf/subfinder_out.txt
echo "[ + ] subfinder - закончил работу"




###-2 Запускаем поиск ip-адресов по найденым поддоменам
echo "[...] запускается nslookup"
for line in `cat ./$name_folder/inf/subfinder_out.txt`
do 
        nslookup $line >> ./$name_folder/worker/nslookup_out_ip.txt
done

# Удаляем лишнюю информацию и оставляем только ip-адреса
sed -i '/^Server:/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i '/answer/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i '/^Name:/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i '/#/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i '/find/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i '/^$/d' ./$name_folder/worker/nslookup_out_ip.txt
sed -i 's/Address: //' ./$name_folder/worker/nslookup_out_ip.txt
### Удаляем лишние ip-адреса
sed -i '/^127/d' ./$name_folder/worker/nslookup_out_ip.txt
#sed -i '/^35/d' ./$name_folder/worker/nslookup_out_ip.txt
#sed -i '/^44.238/d' ./$name_folder/worker/nslookup_out_ip.txt

# Удаляем все повторяющиеся ip-адреса
sort -u ./$name_folder/worker/nslookup_out_ip.txt > ./$name_folder/inf/sort_nslookup_out_ip.txt

# Выводим результат работы  nslookup  записанный в файл
echo "[ + ] nslookup закончил работу"
echo "------------------- Результаты -------------------"
cat ./$name_folder/inf/sort_nslookup_out_ip.txt
echo "--------------------------------------------------"




# ### Поиск скрытых файлов и папок на найденых ip с помощтю ffuf в фоновом режиме
# Создаём файл содержащий в себе список найденных поддоменов, самого доменного имени цели и найденых ip
cat ./$name_folder/inf/subfinder_out.txt >> ./$name_folder/inf/domain_ip.txt
cat ./$name_folder/inf/sort_nslookup_out_ip.txt >> ./$name_folder/inf/domain_ip.txt

# Запускаем поиск скрытых файлов и папок с помощью ffuf 
echo "[...] запускается ffuf"
bash dirrectory_search.sh &




###-3 -------- Здесь цыкл поиска открытых портов для каждого из найдSеных ip и запись в файл
#              новый формат ip:порт
echo "[...] запускается nmap (ищет открытые порты)"

if [[ ${#dom} -ne 0 ]] 
then
        for line_ip in `cat ./$name_folder/inf/subfinder_out.txt`
        do 
                nmap -oN ./$name_folder/worker/nmap_out-domen.txt $line_ip > /dev/null
                cat ./$name_folder/worker/nmap_out-domen.txt >> ./$name_folder/inf/nmap_out-domen_full.txt
        done
fi

for line_ip in `cat ./$name_folder/inf/sort_nslookup_out_ip.txt`
do 
        ###-3.1 Запускаем сканирование открытых портов по найденым поддоменам
        echo "------------------- Сканируется $line_ip :" >> ./$name_folder/worker/nmap_out.txt

        # Запускаем nmap
        nmap -oN ./$name_folder/worker/nmap_out.txt $line_ip > /dev/null

        # Записываем результаты работы nmap в общий файл
        cat ./$name_folder/worker/nmap_out.txt >> ./$name_folder/inf/nmap_out_full.txt

        echo "" >> ./$name_folder/worker/nmap_out.txt
        echo "" >> ./$name_folder/worker/nmap_out.txt


        ###-3.2 Удаляем все строки кроме тех в которых встречается слово  open
        sed -i '/open/!d' ./$name_folder/worker/nmap_out.txt
        ###-3.3 Удаляем всю информацию кроме номера порта
        sed -r 's/[/].+//' ./$name_folder/worker/nmap_out.txt > ./$name_folder/worker/nmap_out_ports.txt
        ###-3.4 Удаляем все повторяющиеся порты
        sort -u ./$name_folder/worker/nmap_out_ports.txt > ./$name_folder/worker/sort_nmap_out_ports.txt

        # Выводим результаты найденных открытых портов для конкретного ip-адреса
        echo_nmap_line_ip="[...] Найденны открытые порты для ip: "
        echo_nmap_line_ip+=$line_ip
        echo $echo_nmap_line_ip
        echo "--------------------------------------------------"
        cat ./$name_folder/worker/sort_nmap_out_ports.txt
        echo "--------------------------------------------------"


        # Записываем в файл отсортированные результаты в виде "ip:порт"
        for line_port in `cat ./$name_folder/worker/sort_nmap_out_ports.txt`
        do
                echo $line_ip":"$line_port >> ./$name_folder/inf/sort_nmap_out_kopiya_ip_ports.txt
        done
        rm ./$name_folder/worker/nmap_out.txt
done

# Удаляем лишние символы из полученых строк
sed -i 's/ //' ./$name_folder/inf/sort_nmap_out_kopiya_ip_ports.txt
sed -i 's/ //' ./$name_folder/inf/sort_nmap_out_kopiya_ip_ports.txt

# Выводим результат работы  nslookup  записанный в файл
echo "[ + ] nmap закончил работу по поиску открытых портов"
echo "--------------- Результаты - nmap ----------------"
cat ./$name_folder/inf/sort_nmap_out_kopiya_ip_ports.txt
echo "--------------------------------------------------"

# # Сохраняем полученные данные о ip и открытых портах на них в БД
python3 recording_ip-ports.py &

# запускаем скрипт
bash vulnerability_search.sh &

# Запускаем скрипт
bash skanirovaniya_domenov_na_versii_OS-PO.sh &

wait
