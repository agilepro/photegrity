<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.HashCounter" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileInputStream" %>
<%@page import="java.io.FileOutputStream" %>
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

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String cmd = UtilityMethods.reqParam(request, "config action page", "cmd");

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

    if (cmd.equals("Add")) {
        int last = dirArray.length;
        String[] oldArray = dirArray;
        dirArray = new String[last+1];
        for (int i=0; i<last; i++) {
            dirArray[i] = oldArray[i];
        }
        dirArray[last] = "xx";
        oldArray = locArray;
        locArray = new String[last+1];
        for (int i=0; i<last; i++) {
            locArray[i] = oldArray[i];
        }
        locArray[last] = "xx";
    }
    else if (cmd.equals("Delete")) {
        if (dirArray.length<2) {
            throw new Exception("Can not delete the last row in the set.  You must always have at least one directory configured.");
        }
        int dirNum = UtilityMethods.defParamInt(request,"del",-1);
        if (dirNum<0 || dirNum>dirArray.length-1) {
            throw new Exception("Hey, select something that you want to delete!");
        }

        String[] newDirArray = new String[dirArray.length-1];
        String[] newLocArray = new String[dirArray.length-1];
        int count = 0;
        boolean found = false;
        for (int i=0; i<dirArray.length; i++) {
            boolean goAhead = (request.getParameter("del"+i)!=null);
            if (i==dirNum) {
                found = true;
            }
            else {
                newDirArray[count] = dirArray[i];
                newLocArray[count] = locArray[i];
                count++;
            }
        }
        dirArray = newDirArray;
        locArray = newLocArray;
    }
    else if (cmd.equals("Save")) {
        for (int i=0; i<dirArray.length; i++) {
            String newVal = request.getParameter("dir"+i).replace('\\','/');
            dirArray[i] = newVal;
            newVal = request.getParameter("loc"+i).replace('\\','/');
            locArray[i] = newVal;
        }
    }
    else if (cmd.equals("Reinit Application")) {
        ImageInfo.garbageCollect();
        String dbdir = (String) props.get("DBDir");
        String localdir = (String) props.get("LocalDir");
        if (dbdir != null) {
            DiskMgr.archivePaths = dbdir.toLowerCase();
        }
        if (localdir != null) {
            DiskMgr.archiveView = localdir.toLowerCase();
        }
    }

    props.put("DBDir", joinString(dirArray));
    props.put("LocalDir", joinString(locArray));

    FileOutputStream fos = new FileOutputStream(f);
    props.store(fos, "JSP Test Configuration Storage");
    fos.flush();
    fos.close();

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Configuration</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Configuration Updated</H1>
<hr>
<table>
    <tr><td>-------</td>
        <td>-------------------------------</td>
        <td>------------</td></tr>
<%
    for (int i=0; i<dirArray.length; i++) {
%>
    <tr><td><%=i%></td>
        <td><%=dirArray[i]%></td>
        <td><%=locArray[i]%></td></tr>
<%
    }
%>
    <tr><td>-------</td>
        <td>-------------------------------</td>
        <td>------------</td></tr>
</table>
<hr>

<a href="config.jsp">Config</a>
<a href="main.jsp"><img src="home.gif"></a>
<hr>
</body>
</HTML>

<%!

    public String joinString(String[] input)
    {
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<input.length-1; i++)
        {
            sb.append(input[i]);
            sb.append(";");
        }
        sb.append(input[input.length-1]);
        return sb.toString();
    }

    %>