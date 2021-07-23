<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%

if (true) {
    throw new Exception("This page is no longer used");
}


    request.setCharacterEncoding("UTF-8");
    response.setContentType("image/jpeg");
    long starttime = System.currentTimeMillis();
    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String path = UtilityMethods.reqParam(request, "File Pict", "path");

    File photoFile = new File(path);

    if (!photoFile.exists()) {
        throw new Exception("The file '"+path+"' does not exist!");
    }

    FileInputStream fis = new FileInputStream(photoFile);

    OutputStream os = response.getOutputStream();

    byte[] buf = new byte[2048];
    int got = fis.read(buf);
    while (got>=0) {
        os.write(buf,0,got);
        got = fis.read(buf);
    }
    fis.close();
%>
