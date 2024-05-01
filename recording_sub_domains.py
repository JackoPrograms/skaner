### Часть программы (ызывается из Часть скрипта 1): записывает в отдельную таблицу найденные поддомены
# ----------------------------------------------------------------------------



import sqlite3



# Считываем имя рабочей папки
with open('name_folder.txt', 'r') as file:
    name_folder = file.read()
    name_folder = name_folder.strip("\n")
# Имя пути до файла с БД
path_file = f"./{name_folder}/inf/scan_results.db"
# Имя сканируемого домена (цели сканирования)
with open('domain_name.txt', 'r') as file:
    domain = file.read().strip("\n")
    

def create_database():
    # Создание базы данных SQLite и таблиц
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS sub_domains
                 (domain TEXT, sub_domain TEXT)''')

    conn.commit()
    conn.close()

def insert_data(sub_domains):
    # Вставка данных в таблицы базы данных
    conn = sqlite3.connect(path_file)
    c = conn.cursor()

    for i in sub_domains:
        c.execute("INSERT INTO sub_domains VALUES (?, ?)",
                  (domain, i.strip("\n")))

    conn.commit()
    conn.close()

def parse_nmap_output(file_path):
    # Парсинг вывода nmap для извлечения информации
    sub_domains = []    

    with open(file_path, 'r') as file:
        for line in file:
            sub_domains.append(line)

    return sub_domains
    


nmap_output_file = f"./{name_folder}/inf/subfinder_out.txt" # Путь до файла с результатами поиска поддоменов
sub_domains_all = parse_nmap_output(nmap_output_file)
create_database()
insert_data(sub_domains_all)
