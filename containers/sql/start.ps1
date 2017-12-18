
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=!QAZxsw2" -p 1401:2001 --name mssql1 
-d microsoft/mssql-server-linux:2017-latest
