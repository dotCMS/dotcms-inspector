import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;

public class Inspect 
{
  public static void main(String[] args)
  {
String userName = (args[0]).trim();
String password = (args[1]).trim();
String dbname = (args[2]).trim();
String url = "jdbc:mysql://localhost:3306/" + dbname;  

Connection conn = null;
          try
          {
              Class.forName ("com.mysql.jdbc.Driver").newInstance ();
              conn = DriverManager.getConnection (url, userName, password);

                Statement s = conn.createStatement ();
                s.executeQuery ("select * from publishing_end_point");
                ResultSet rs = s.getResultSet ();
                int count = 0;
				
                while (rs.next ())
                {                       
                    System.out.println (count + " rows were retrieved");
                    count++;    
                }
				rs.close ();
                s.close ();

        }
        catch (Exception e) {
             System.out.println(e.getMessage());
        }

}
  
}

