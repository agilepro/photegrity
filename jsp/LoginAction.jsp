<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"
%><%@page errorPage="error.jsp"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.LoginAttemptRecord"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%
    request.setCharacterEncoding("UTF-8");

    String goPage = request.getParameter("go");
    if (goPage == null || goPage.length()==0) {
        throw new Exception("The LoginAction page needs to have a 'go' parameter with the URL of the page to redirect to once the use has entered a correct password.  That 'go' parameter is missing, which is usually a programming error from the people who wrote the JSP page.");
    }

    //This is to help prevent hacking passwords.  Incorrect results yeild a longer delay below
    Thread.sleep(1000);

    String requestIPAddr = request.getRemoteAddr();
    LoginAttemptRecord.checkLoginThreshold(requestIPAddr);

    // update the failure count, just in case there is ANY failure
    LoginAttemptRecord.incrementCount(requestIPAddr);

    String userName = request.getParameter("userName");
    String password = request.getParameter("password");
    if ( userName == null) {
        Thread.sleep(3000);
        throw new Exception("You must provide a User Name!");
    }
    if ( password == null) {
        Thread.sleep(3000);
        throw new Exception("You must provide a Password!");
    }
    userName = userName.trim();
    password = password.trim();
    if ( userName.length()==0 ||
        password.length()==0 ) {
        Thread.sleep(3000);
        throw new Exception("You must provide a User Name and Password!");
    }

    String tpas = "aaa"+userName;
    if (!password.equals(tpas)) {
        Thread.sleep(3000);
        throw new Exception("Either the user name is incorrect, or the password supplied does not match.");
    }

    // successful login means that we need to assure the count is cleared
    LoginAttemptRecord.clearCount(requestIPAddr);

    session.setAttribute("userName", userName);
    session.setAttribute("password", password);

    ServletContext sc = session.getServletContext();
    String configPath = sc.getRealPath("/config.txt");

    File f = new File(configPath);
    if (!f.exists()) {
        throw new Exception("Did not find file '"+f.getAbsolutePath()+"'");
    }
    FileInputStream fis = new FileInputStream(f);
    Properties props = new Properties();
    props.load(fis);

    String dbdir = (String) props.get("DBDir");
    String localdir = (String) props.get("LocalDir");
    if (dbdir != null) {
        DiskMgr.archivePaths = dbdir.toLowerCase();
    }
    if (localdir != null) {
        DiskMgr.archiveView = localdir.toLowerCase();
    }

    response.sendRedirect(goPage);

%>
