<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" isErrorPage="true" session="true"
%><% // NOTE: The method setCharacterEncoding must be called before reading request parameters (see documentation for HttpServletRequest).
     request.setCharacterEncoding("UTF-8");request.getParameterNames(); //Need dummy call for WL9.1
%><%@page import="java.io.PrintWriter"
%>

<!-- ======================== EXCEPTION NOTE ====================== -->

<html>
<body class="bodyClass">
<p>
<%=exception.toString()%>
</p>
<pre>
<%
   out.flush();
   PrintWriter pw = new PrintWriter(out);
   exception.printStackTrace();
   pw.flush();

%>
</pre>
</body>
</html>
