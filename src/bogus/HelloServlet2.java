package bogus;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

/**
 * Simple servlet used to test the use of packages.
 * <P>
 * Taken from More Servlets and JavaServer Pages from Prentice Hall and Sun
 * Microsystems Press, http://www.moreservlets.com/. &copy; 2002 Marty Hall; may
 * be freely used or adapted.
 */

@SuppressWarnings("serial")
public class HelloServlet2 extends HttpServlet {
	public void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		response.setContentType("text/html");
		PrintWriter out = response.getWriter();
		String docType = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 " + "Transitional//EN\">\n";
		out.println(docType + "<HTML>\n" 
		        + "<HEAD><TITLE>Hello (2)</TITLE></HEAD>\n"
				+ "<BODY BGCOLOR=\"#FDF5E6\">\n" 
				+ "<H1>Hello (2)</H1>\n" 
				+ "</BODY></HTML>");
	}
}
