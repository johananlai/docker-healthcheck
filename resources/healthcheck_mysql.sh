mysql -u root "-ppassword" -e "SELECT User, Host, plugin FROM mysql.user" && mysql -u root "-ppassword" -e "create database test1;" && mysql -u root "-ppassword" -e "drop database test1;"
