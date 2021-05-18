#!/bin/bash
export DEBIAN_FRONTEND=noninteractive ;
set -eu ; # abort this script when a command fails or an unset variable is used.
#set -x ; # echo all the executed commands.

printf '\nInstalling PostgreSQL.\n' ;
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -q update
sudo apt-get install -yqq postgresql-10
#postgresql-contrib

# // on Debian (stretch) latest stable (11 at the time of writting)
#sudo apt-get -yqq install postgresql postgresql-contrib 2>&1>/dev/null ;

# // on some systems / version initdb may be needed.
# if [[ $(uname -ar) == *"centos"* ]] ; then sudo postgresql-setup initdb ; fi ;

if [[ ! ${PG_IP_CIDR+x} ]]; then PG_IP_CIDR='192.168.10.0/0' ; fi ;
if [[ ! ${PG_ADMIN+x} ]]; then PG_ADMIN='myapp_admin' ; fi ;
#if [[ ! ${PG_USER+x} ]]; then PG_USER='vault-edu' ; fi ;
if [[ ! ${PG_SECRET+x} ]]; then PG_SECRET='SECRET' ; fi ;
if [[ ! ${PG_DB+x} ]]; then PG_DB='myapp' ; fi ;

# // get postgresql directory path for pg_hba.conf
PG_CONF=$(sudo -u postgres psql -c "SHOW config_file;" | head -n-2 | tail -n1) ;
PG_PATH_CONF=$(dirname ${PG_CONF}) ;
PG_CONF_HBA="${PG_PATH_CONF}/pg_hba.conf" ;
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" ${PG_CONF} ;
# // increase PostgreSQL log level to debug
sed -i "s/#log_statement = 'none'/log_statement = 'ddl'/g" ${PG_CONF} ;

# // backup existing config (if any) and set config restart service.
mv ${PG_CONF_HBA} ${PG_PATH_CONF}/old.pg_hba_$(date +%s).conf ;
printf """
local   all             postgres                                trust
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             0.0.0.0/0               md5
host    all             all             ${PG_IP_CIDR}           md5

""" > ${PG_CONF_HBA} ;
sudo service postgresql restart ;

psql -U postgres -c "SELECT version();" ; # // display version info
psql -U postgres -c "CREATE DATABASE ${PG_DB};" ;
psql -U postgres -c "CREATE ROLE \"${PG_ADMIN}\" WITH SUPERUSER LOGIN CREATEROLE PASSWORD '${PG_SECRET}';" ; # // db admin user
#psql -U postgres -c "CREATE USER \"${PG_USER}\" WITH PASSWORD '${PG_SECRET}';" ;
#psql -U postgres -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"${PG_USER}\";" ;

#psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${PG_DB} to ${PG_ADMIN};" ;
#psql -U postgres -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_SECRET}';" ;

