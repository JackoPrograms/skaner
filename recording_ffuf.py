### Часть программы (вызывается из Часть скрипта 2.1.): записывает в таблицу переанный поддомен и найденные скрытые файлы и папки на этом подомене. 
# ----------------------------------------------------------------------------



import sqlite3
import sys
# import re
import json



domain_ip = f"{sys.argv[1]}"  # Аргумент переданный от скрипта (имя суб домена)
name_file_out_ffuf = f"{sys.argv[2]}"  # Аргумент переданный от скрипта (имя файла с результатами сканирования ffuf)

# Считываем имя рабочей папки
with open('name_folder.txt', 'r') as file:
    name_folder = file.read()
    name_folder = name_folder.strip("\n")
# Имя пути до файла с БД
path_file = f"./{name_folder}/inf/scan_results.db"


def create_database():
    # Создание базы данных SQLite и таблиц
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS found_files
                 (sub_domain TEXT, name_file_folder TEXT)''')

    conn.commit()
    conn.close()
    
    
def insert_data(files_folders):
    # Вставка данных в таблицы базы данных
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    for file_folder in files_folders:
        c.execute("INSERT INTO found_files VALUES (?, ?)",
                  (domain_ip, file_folder))

    conn.commit()
    conn.close()


def parse_ffuf_output(file_path):
    # Парсинг вывода ffuf для извлечения информации о найденных файлах и папках

    # Загрузить данные JSON
    with open(file_path, 'r') as file:
        data = json.load(file)

    # Извлечь информацию о найденных файлах и папках
    files_folders = []
    for result in data['results']:
        files_folders.append(result['url'].split('/')[-1])

    return files_folders
        

ffuf_output_file = name_file_out_ffuf # Путь до файла с результатами работы ffuf
files_folders_all = parse_ffuf_output(ffuf_output_file)
create_database()
insert_data(files_folders_all)

print(f"[ + ] Произведена запись в БД полученой информации от ffuf для адреса: {domain_ip}")
