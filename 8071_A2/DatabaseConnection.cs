using System.Data.Odbc;
using System.Reflection.Metadata.Ecma335;

namespace _8071_A2
{
    internal class DatabaseConnection
    {
        private static string connectionString
        {
            get
            {
                const string host = "localhost";
                const string username = "sa";
                const string database = "COMP8071";
                const string password = "P@ssw0rd";
                return "Driver={SQL Server};Server=" + host + ";Database=" + database + ";Uid=" + username + ";Pwd=" + password + ";";
            }
        }
            

        internal static int InsertData(string statement)
        {
            var command = new OdbcCommand(statement);

            using OdbcConnection connection = new(connectionString);
            command.Connection = connection;
            connection.Open();
            return command.ExecuteNonQuery();
        }

    }
}
