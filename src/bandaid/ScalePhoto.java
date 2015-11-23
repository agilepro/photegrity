/*
 * ScalePhoto.java
 */
package bandaid;

import java.io.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import bandaid.Thumbnail;
import java.net.URLDecoder;
import bogus.UtilityMethods;

@SuppressWarnings("serial")
public class ScalePhoto extends javax.servlet.http.HttpServlet {

	public void doGet(HttpServletRequest req, HttpServletResponse resp) {
		OutputStream out = null;
		try {
			resp.setContentType("image/jpeg");
			req.setCharacterEncoding("UTF-8");

			String uri = req.getRequestURI();
			// URI starts with /scale/ so remove this
			String relPath = URLDecoder.decode(uri.substring(7), "UTF-8");
			File photoFile = new File("g:/photos/" + relPath);

			int scaleX = UtilityMethods.defParamInt(req, "x", 600);
			int scaleY = UtilityMethods.defParamInt(req, "y", 600);

			if (!photoFile.exists()) {
				// photoFile = new File("G:/Photos/PhotoDoesNotExist.jpg");
				resp.setContentType("test/html");
				Writer w = new OutputStreamWriter(resp.getOutputStream());
				w.write("<html><bodu><ul><li>No sure what '");
				w.write(relPath);
				w.write("' means.</ul></body></html>");
				w.flush();
				return;
			}

			out = resp.getOutputStream();

			Thumbnail.scalePhoto(photoFile, out, scaleX, scaleY, 90);
		}
		catch (Exception e) {
			try {
				resp.setContentType("test/html");
				if (out == null) {
					out = resp.getOutputStream();
				}
				Writer w = new OutputStreamWriter(out);
				w.write("<html><body><ul><li>Exception: ");
				w.write(UtilityMethods.getErrorString(e));
				w.write("</ul></body></html>");
				w.flush();
			}
			catch (Exception eeeee) {
				// nothing we can do here...
			}
		}
	}

}
