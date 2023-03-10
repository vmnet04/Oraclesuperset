FROM python:2.7.11

MAINTAINER vmnet02 vmnet02@gmail.com


# Oracle instantclient
COPY oracle/instantclient-basic-linux.x64-12.2.0.1.0.zip /tmp/
COPY oracle/instantclient-jdbc-linux.x64-12.2.0.1.0.zip /tmp/
COPY oracle/instantclient-odbc-linux.x64-12.2.0.1.0-2.zip /tmp/
COPY oracle/instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/
COPY oracle/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /tmp/

RUN apt-get update  -y && \
    apt-get install -y unzip libaio-dev && \
    # install Oracle drivers / instantclient:
    unzip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /usr/local/ && \
    unzip /tmp/instantclient-jdbc-linux.x64-12.2.0.1.0.zip -d /usr/local/ && \
    unzip /tmp/instantclient-odbc-linux.x64-12.2.0.1.0-2.zip -d /usr/local/ && \
    unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /usr/local/ && \
    unzip /tmp/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /usr/local/ && \
    ln -s /usr/local/instantclient_12_2 /usr/local/instantclient && \
    ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus && \
    # install cx_Oracle via pip:
    pip install cx_Oracle==5.2 && \
    # clean up:
    apt-get clean -y && \
    apt-get autoclean && \
    apt-get autoremove --purge && \
    rm /tmp/instantclient-* && \

ENV TERM=vt100
ENV ORACLE_HOME="/usr/local/instantclient"
ENV LD_LIBRARY_PATH="/usr/local/instantclient"
RUN export PATH=$PATH:/usr/local/instantclient/bin

RUN echo '/usr/local/instantclient/' | tee -a /etc/ld.so.conf.d/oracle_instant_client.conf && ldconfig

RUN apt-get install libaio-dev libsasl2-dev libldap2-dev -y && apt-get clean -y

# Install superset
RUN pip install cx_Oracle superset

# copy admin password details to /superset for fabmanager
RUN mkdir /superset
COPY admin.config /superset/

# Create an admin user
RUN /usr/local/bin/fabmanager create-admin --app superset < /superset/admin.config

# Initialize the database
RUN superset db upgrade

# Create default roles and permissions
RUN superset init

# Load some data to play with
RUN superset load_examples

# Start the development web server
CMD superset runserver -d
