<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.HashCounter" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileInputStream" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.io.OutputStream" %>
<%@page import="java.io.PrintWriter" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Properties" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    /*
    if (session.getAttribute("userName") == null) {
        %><!--jsp:include page="PasswordPanel.jsp" flush="true"/--><%
        return;
    }
    
    if (!DiskMgr.isInitialized()) {
        %><!--jsp:include page="PasswordPanel.jsp" flush="true"/--><%
        return;
    }
    */
    
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    int colInt = UtilityMethods.getSessionInt(session, "columns", 3);
    int imageNum = UtilityMethods.getSessionInt(session, "imageNum", 3);

    ServletContext sc = session.getServletContext();
    String configPath = sc.getRealPath("/config.txt");

    File f = new File(configPath);
    if (!f.exists()) {
        throw new Exception("Did not find file '"+f.getAbsolutePath()+"'");
    }
    FileInputStream fis = new FileInputStream(f);
    Properties props = new Properties();
    props.load(fis);

    String[] dirArray = UtilityMethods.splitOnDelimiter((String)props.get("DBDir"), ';');
    String[] locArray = UtilityMethods.splitOnDelimiter((String)props.get("LocalDir"), ';');

    Enumeration e = props.keys();
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Configuration</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Configuration</H1>
<hr>
<form action="configAction.jsp" method="post">

<%
    for (int i=0; i<dirArray.length; i++) {
%>

    Directory <%=i%>:  <input type="text" name="dir<%=i%>" value="<%=dirArray[i]%>">
                  <input type="text" name="loc<%=i%>" value="<%=locArray[i]%>">
                  <input type="radio" name="del" value="<%=i%>"><br>
<%
    }
%>

<input type="submit" name="cmd" value="Add">
<input type="submit" name="cmd" value="Delete">
<input type="submit" name="cmd" value="Save">
<input type="submit" name="cmd" value="Reinit Application">

</form>

<a href="main.jsp"><img src="home.gif"></a>
<hr>
Debug:
<table>
<%
    while (e.hasMoreElements()) {
        String key = (String) e.nextElement();
        String val = (String) props.get(key);
%>
    <tr><td><%=key%></td>
        <td><%=val%></td></tr>
<%
    }
%>
</table>
</body>
</HTML>
