/*
 * Thumbnail.java (requires Java 1.2+)
 */
package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.purplehillsbooks.json.JSONException;

@SuppressWarnings("serial")
public class ShowImage extends javax.servlet.http.HttpServlet {

    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        OutputStream out = null;
        try {

            // not initialized, so abort
            DiskMgr.assertInitialized();
            HttpSession session = req.getSession();
            if (session.getAttribute("userName") == null) {
                throw new JSONException("Not logged in");
            }

            out = resp.getOutputStream();
            resp.setContentType("image/jpeg");
            req.setCharacterEncoding("UTF-8");

            String pathInfo = req.getPathInfo();
            String[] pathParts = UtilityMethods.splitOnDelimiter(pathInfo, '/');

            String disk = pathParts[1];

            int filePart = pathParts.length - 1;
            String fileName = pathParts[filePart];

            StringBuffer path = new StringBuffer();
            for (int i = 2; i < filePart; i++) {
                path.append(pathParts[i]);
                path.append("/");
            }
            path.append(fileName);

            DiskMgr dm = DiskMgr.getDiskMgr(disk);
            File filePath = dm.getFilePath(path.toString());

            //synchronized (ii) {
                FileInputStream fis = new FileInputStream(filePath);

                byte[] buf = new byte[2048];

                int amtRead = fis.read(buf);
                while (amtRead > 0) {
                    out.write(buf, 0, amtRead);
                    amtRead = fis.read(buf);
                }
                fis.close();
            //}
            out.flush();
        }
        catch (Exception e) {
            try {
                resp.setContentType("text/html");
                if (out == null) {
                    out = resp.getOutputStream();
                }
                Writer w = new OutputStreamWriter(out);
                w.write("<html><body><ul><pre>Exception: ");
                w.write(UtilityMethods.getErrorString(e));
                w.write("</pre><hr/></body></html>");
                w.flush();
            }
            catch (Exception eeeee) {
                // nothing we can do here...
            }
        }
    }
}
