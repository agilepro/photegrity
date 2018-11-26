<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Stack"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    groupName = newsGroup.getName();


    String dig = UtilityMethods.reqParam(request, "News Details Page", "d");
    String f = UtilityMethods.reqParam(request, "News Details Page", "f");
    String sort= UtilityMethods.defParam(request, "sort", "dig");
    String start= UtilityMethods.defParam(request, "start", "0");
    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    String thisPage = "newsDetail2.jsp?"+startPart+"&d="+URLEncoder.encode(dig,"UTF-8")+"&f="+URLEncoder.encode(f,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig, f);
    List<NewsArticle> articles = bunch.getArticles();

    if (articles.size() == 0) {
        throw new Exception("Unable to get any articles for ("+dig+")");
    }

    if ("dig".equals(sort)) {
        NewsArticle.sortByDigest(articles);
    }
    else {
        NewsArticle.sortByNumber(articles);
    }

    String template = bunch.getTemplate();
    if (template==null || template.length()==0) {
        template = bunch.tokenFill();
    }
    String folder = bunch.getFolderLoc();
    boolean folderExists = bunch.hasFolder();

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }
    while (destVec.size()>8) {
        destVec.remove(8);
    }

    //set up the location that files automatically go to for Cover, Flogo, etc.
    String prefFolder = "";
    if (destVec.size()>0) {
        prefFolder = destVec.get(0);
    }

    String zingpat = (String) session.getAttribute("zingpat");

    String queueMsg = "("+NewsAction.getActionCount()+" tasks)";

    //need a sample article to deal with
    NewsArticle firstArticle = articles.get(0);
    String fromUser = firstArticle.getHeaderFrom();

    JSONArray allArts = new JSONArray();
    for (NewsArticle art : articles) {
        JSONObject jobj = new JSONObject();
        jobj.put("num", art.articleNo);
        jobj.put("from", art.getHeaderFrom());
        jobj.put("subject", art.getHeaderSubject());
        jobj.put("dig", art.getHeaderSubject());
        jobj.put("dig", art.getHeaderSubject());
        jobj.put("viz", art.isOnDisk());
        String localPath = "";
        File filePathX = art.getFilePath();
        if (filePathX!=null) {
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePathX);
            localPath = dm.diskName + "/" + dm.getOldRelativePathWithoutSlash(filePathX);
        }
        jobj.put("localPath", localPath);
        allArts.put(jobj);
    }
    allArts.write(out, 2, 0);

%>

