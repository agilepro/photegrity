<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.NewsAction"
%><%@page import="com.purplehillsbooks.photegrity.NewsActionDownloadAll"
%><%@page import="com.purplehillsbooks.photegrity.NewsActionDownloadFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsActionSeekBunch"
%><%@page import="com.purplehillsbooks.photegrity.NewsActionSeekABit"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %>You must logged in to delete a file<%
        return;
    }

    String path       = UtilityMethods.defParam(request, "path", null);
    if (path==null) {
        %>Need a full path name passed as a parameter named 'path'<%
        return;
    }

    File   filePath = new File(path);
    if (!filePath.exists()) {
        %>The path does not exist: <%=path%>'<%
        return;
    }
        
    if (!filePath.delete()) {
        %>Delete did not work for some reason: <%=path%>'<%
        return;
    }

%>
OK, file deleted.
