# FROM kalilinux/kali-rolling

# WORKDIR /script

# COPY . /script

# RUN apt-get update && apt-get install -y golang

# RUN bash requirements.sh

# ENTRYPOINT [ "bash", "script.sh" ]

# CMD [ "", "", "" ]




FROM kalilinux/kali-rolling

WORKDIR /script

COPY . /script

RUN apt-get -y update 
RUN apt-get install -y golang
RUN apt-get install -y ffuf
RUN apt install subfinder
RUN apt install dnsutils -y
RUN apt-get install nmap -y
RUN apt install python3 -y

RUN apt install nuclei -y
RUN apt-get install git -y
RUN git clone https://github.com/projectdiscovery/nuclei-templates.git
# RUN nuclei -update-templates

# RUN apt-get update && apt-get install -y dos2unix
# RUN dos2unix script.sh

# RUN bash requirements.sh

RUN apt install python3-pip -y
RUN pip install django

ENTRYPOINT ["python3", "./VKR/manage.py", "runserver", "0.0.0.0:8000"]

CMD ["--noreload"]