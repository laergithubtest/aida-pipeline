FROM openjdk:8-jdk

RUN echo 'deb http://ftp.de.debian.org/debian jessie main' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org/debian-security jessie/updates main ' >> /etc/apt/sources.list
RUN echo 'deb http://ftp.de.debian.org/debian sid main' >> /etc/apt/sources.list

WORKDIR /root

RUN apt-get update

RUN apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev

### Install Python
RUN wget https://www.python.org/ftp/python/3.6.6/Python-3.6.6.tgz
RUN tar xvf Python-3.6.6.tgz

WORKDIR /root/Python-3.6.6
RUN ./configure --enable-optimizations --with-ensurepip=install
RUN make altinstall
RUN python --version
RUN python3.6 --version

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3.6 get-pip.py
### set python 3 as the default python version
RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python3.6 1
RUN python --version
RUN pip install --upgrade pip requests setuptools pipenv


RUN apt-get install -y libpq-dev libfreetype6-dev libxft-dev libncurses-dev libopenblas-dev gfortran libblas-dev liblapack-dev libatlas-base-dev zlib1g-dev g++
RUN apt-get install -y libpoppler-cpp-dev pkg-config
#RUN apt-get install -y libxml2 libxml2-dev libxslt-dev

RUN apt-get install -y libenchant1c2a
RUN apt-get install -y git
RUN apt-get install -y vim

RUN apt-get install -y libreoffice
RUN apt-get install -y libmagic-dev

ARG gitusername
ARG gitpassword

WORKDIR /root
#RUN git clone "https://$gitusername:$gitpassword@github.com/laergithubtest/constants.git" && cd /root/constants #&& git checkout -b deploy v2018.12.26.0
RUN git clone "https://$gitusername:$gitpassword@github.com/laergithubtest/constants.git" && cd /root/constants && git checkout -b deploy v2019.01.04.0
WORKDIR /root/constants/python/aida-common
RUN /bin/bash install_requirements.sh
RUN python install.py


WORKDIR /root
RUN apt-get install -y maven
ARG maven
RUN mkdir /root/.m2
RUN echo $maven > /root/.m2/settings.xml

RUN git clone "https://$gitusername:$gitpassword@github.com/laergithubtest/search-indexer.git" && cd /root/search-indexer && git checkout master
WORKDIR /root/search-indexer
RUN mvn clean install -DskipTests
RUN chmod +x build.sh

ARG google_api_key
RUN mkdir /root/auth
RUN /bin/echo $google_api_key > /root/auth/google_api.key
ENV GOOGLE_APPLICATION_CREDENTIALS=/root/auth/google_api.key

ARG mongo_db_key
ENV MONGODB_KEY=$mongo_db_key

ARG google_knowledge_key
ENV GOOGLE_KNOWLEDGE_GRAPH_KEY=$google_knowledge_key

ARG bing_search_key
ENV BING_SEARCH_KEY=$bing_search_key

ARG pipl_key
ENV PIPL_KEY=$pipl_key

ARG clearbit_key
ENV CLEARBIT_KEY=$clearbit_key

ADD requirements.txt /root
WORKDIR /root
RUN pip install -r requirements.txt

WORKDIR /root
COPY aida-raw-data-loader/code/ /root/aida-raw-data-loader/
COPY aida-kb/code/ /root/aida-kb/
COPY aida-pdf-ocr/code/ /root/aida-pdf-ocr/
COPY aida-document-parsing/code/ /root/aida-document-parsing/
COPY aida-mongo/code/ /root/aida-mongo/

WORKDIR /root
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.2.1/wait /wait
RUN chmod +x /wait