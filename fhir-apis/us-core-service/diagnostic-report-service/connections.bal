import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;

# Initialize database client
final jdbc:Client dbClient = check new (
    url = string `jdbc:mysql://${dbHost}:${dbPort}/${dbName}`,
    user = dbUsername,
    password = dbPassword
);