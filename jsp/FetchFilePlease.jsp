<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page errorPage="Exception.jsp"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.OutputStream"
%><%@page import="java.net.URL"
%><%@page import="java.net.URLConnection"
%><%@page import="java.net.URLEncoder"
%><%
    request.setCharacterEncoding("UTF-8");

    String enc  = request.getParameter("enc");
    if (enc==null) {
        enc = "UTF-8";
    }
    String path = request.getParameter("path");
    if (path==null || path.length()<=4) {
        %>
        <html>
        <head>
            <title>Keith's File Fetcher</title>
            <link href="mystyle.css" rel="stylesheet" type="text/css"/>
        </head>
        <body BGCOLOR="#E6FDF5">
        <h1>Keith's File Fetcher</h1>
        <form action="FetchFilePlease.jsp" method="get">
          <input type="text" name="path" value="" size=80>
          <input type="submit" value="Get">
          <input type="text" name="enc" value="<%= enc %>">
        </form>
        <p>Enter the URL of a file that can be accessed on the web.
        This utility will read the file, and send it back to you at
        this address.  This was created to allow an unsigned Java
        applet, launched from this site, to retrieve files from the
        sites outside of this one.</p>
        <p>You can test this by entering the address of a well known
        web page, and you will see the page (if it is found) displayed
        in your browser.  But notice the page embeds graphics using relative
        paths, they will not load because the browser thinks this is coming
        from the IBPM application, and the graphics are not there.</p>
        <p>Please know that this is a hidden and undocumented page in the
        ibpm application, and if you are looking at this page, reading
        this text, or reading the source of this page, you owe Keith
        Swenson a sushi dinner at the resteraunt of his choice!</p>
        </body>
        </html>
        <%
        return;
    }
    int lastSlash = path.lastIndexOf("/");
    if (lastSlash<0) {
        throw new Exception("Hey, you have to have at least one slash in that URL!");
    }
    //String basePath = path.substring(0, lastSlash+1);

    if (path.length()>4) {
        URL testUrl = new URL(path);
        URLConnection uc = testUrl.openConnection();
        if (uc == null) {
            throw new Exception("Got a null URLConnection object!");
        }
        InputStream is = uc.getInputStream();
        if (is == null) {
            throw new Exception("Got a null content object!");
        }
        OutputStream myOut = response.getOutputStream();
        if (myOut == null) {
            throw new Exception("Got a null output stream!");
        }
        byte[] bb = new byte[2048];
        int amtRead = is.read(bb);
        int amtTotal = amtRead;
        while (amtRead > 0) {
            myOut.write(bb, 0, amtRead);
            amtRead = is.read(bb);
            amtTotal += amtRead;
        }
    }
%>