package bogus;

import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.URLDecoder;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;

@SuppressWarnings("serial")
public class SpecialServlet extends HttpServlet {

	public SpecialServlet() {

	}

	public void init() {

	}

	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, java.io.IOException {
		request.setCharacterEncoding("UTF-8");
		response.setContentType("text/html");

		OutputStream ostream = response.getOutputStream();
		Writer w = new OutputStreamWriter(ostream, "UTF-8");
		String page = "<html><body><h3>Here is my page </h3><table>"
				+ "<tr><td>getRequestedURL:</td><td>" + request.getRequestURL() + "</td></tr>"
				+ "<tr><td>getRequestedURI:</td><td>" + request.getRequestURI() + "</td></tr>"
				+ "<tr><td>getPathTranslated:</td><td>" + request.getPathTranslated()
				+ "</td></tr>" + "<tr><td>decoded:</td><td>"
				+ URLDecoder.decode(request.getRequestURL().toString(), "UTF-8") + "</td></tr>"
				+ "</table></body></html>";
		response.setContentLength(page.length());
		w.write(page);
		w.flush();
	}
}