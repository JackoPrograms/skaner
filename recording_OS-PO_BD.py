### Часть программы (вызывается из Часть скрипта 4): отвечает за парсинг информации из результатов сканирования версий ОС и ПО для конкретного ip  
# ----------------------------------------------------------------------------



import sqlite3
import re
import sys



argument = sys.argv[1]  # Аргумент переданный от скрипта (имя файла)

# Считываем имя рабочей папки
with open('name_folder.txt', 'r') as file:
    name_folder = file.read()
    name_folder = name_folder.strip("\n")
# Имя пути до файла с БД
path_file = f"./{name_folder}/inf/scan_results.db"
# ip-адрес:  для которого получены результаты сканирования
ip = argument[6:-4]


# Вывод информации о том что информация для одного из ip была найдена nmap
print(f"[...] Найденны версии ОС и ПО для ip: {ip}")
    

def create_database():
    # Создание базы данных SQLite и таблиц
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS services
                 (ip TEXT, port TEXT, state TEXT, service TEXT, version TEXT)''')

    c.execute('''CREATE TABLE IF NOT EXISTS os_info
                 (ip TEXT, running_services TEXT, os_info TEXT, os_guesses TEXT)''')

    conn.commit()
    conn.close()

def insert_data(services, os_info):
    # Вставка данных в таблицы базы данных
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    for service in services:
        c.execute("INSERT INTO services VALUES (?, ?, ?, ?, ?)",
                  (ip, service['Порт'], service['Состояние'], service['Сервис'], service['Версия']))

    c.execute("INSERT INTO os_info VALUES (?, ?, ?, ?)",
              (ip, os_info['Запущенные сервисы'], os_info['Информация об ОС'], os_info['Догадки по ОС']))

    conn.commit()
    conn.close()

def parse_nmap_output(file_path):
    # Парсинг вывода nmap для извлечения информации
    services = []
    os_info = {'Запущенные сервисы': '', 'Информация об ОС': '', 'Догадки по ОС': ''}

    with open(file_path, 'r') as file:
        for line in file:
            if re.match(r'\d+\/\w+', line):  # Поиск строк с портами
                port_info = line.split()
                if len(port_info) >= 4:
                    port = port_info[0]
                    state = port_info[2]
                    service = port_info[3]
                    version = ' '.join(port_info[4:])
                    services.append({'Порт': port, 'Состояние': state, 'Сервис': service, 'Версия': version})

            if "Running" in line:          # Поиск информации о запущенных сервисах
                running_info = line.split(': ')[1].strip()
                os_info['Запущенные сервисы'] += f"{running_info}\n"

            if "OS CPE:" in line:          # Поиск информации об ОС
                os_cpe_info = line.split(': ')[1].strip()
                os_info['Информация об ОС'] += f"{os_cpe_info}\n"

            if "Aggressive OS guesses" in line:  # Поиск агрессивных догадок об операционной системе
                aggressive_guesses = line.split(': ')[1].strip()
                os_info['Догадки по ОС'] += f"{aggressive_guesses}\n"

    return services, os_info



nmap_output_file = f"./{name_folder}/worker/version_OS-PO/{argument}" # Путь до файла с результатами сканирования версий ОС и ПО
services_data, os_info_data = parse_nmap_output(nmap_output_file)
create_database()
insert_data(services_data, os_info_data)


# Вывод информации о том что информация для одного из ip была записана в БД
print(f"[ + ] Произведена запись в БД полученой информации о версии ОС и ПО для ip: {ip}")

