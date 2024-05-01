### Часть программы (вызывается из Часть скрипта 1): записывает в отдельную таблицу ip и найденные для них открытые порты
# ----------------------------------------------------------------------------



import sqlite3



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

    c.execute('''CREATE TABLE IF NOT EXISTS ip_ports
                 (ip TEXT, port TEXT)''')

    conn.commit()
    conn.close()
    
def insert_data(ip_port):
    # Вставка данных в таблицы базы данных
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    for i in ip_port:
        c.execute("INSERT INTO ip_ports VALUES (?, ?)",
                  (i['ip'], i['port']))

    conn.commit()
    conn.close()
    
def parse_nmap_output(file_path):
    # Парсинг вывода nmap для извлечения информации
    ip_port = []

    with open(file_path, 'r') as file:
        for line in file:
            ip, port = line.split(":")
            ip_port.append({'ip': ip, 'port': port.strip("\n")})
    
    return ip_port
        

nmap_output_file = f"./{name_folder}/inf/sort_nmap_out_kopiya_ip_ports.txt" # Путь до файла с результатами поиска открытых port на найденых ip
ip_port_all = parse_nmap_output(nmap_output_file)
create_database()
insert_data(ip_port_all)





