<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounterIgnoreCase"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.LocalMapping"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.PosPat"
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
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.streams.JavaScriptWriter"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="org.workcast.json.JSONArray"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/plain;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    groupName = newsGroup.getName();


    String dig = UtilityMethods.reqParam(request, "News Files Listing", "d");
    String sort= UtilityMethods.defParam(request, "sort", "dig");
    String thisPage = "newsFiles.jsp?d="+URLEncoder.encode(dig,"UTF-8");

    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig);

    boolean hasData = bunch.hasTemplate();

    List<NewsFile> files = null;

    if (hasData) {
        files = bunch.getFiles();
    }
    else {
        //create an empty vector
        files = new Vector<NewsFile>();
    }

    String folder = bunch.getFolderLoc();
    boolean folderExists = bunch.hasFolder();
    File   folderPath = bunch.getFolderPath();
    File[] folderChildren = new File[0];
    if (folderPath.exists()) {
        folderChildren = folderPath.listFiles();
        if (folderChildren==null) {
            //fix broken logic of system call.  Should never return null!
            folderChildren = new File[0];
        }
    }

    Vector<String> tagList = new Vector<String>();
    boolean isTag = false;

    DiskMgr mgr = DiskMgr.getDiskMgrOrNull(newsGroup.groupName);
    if (mgr==null) {
        //throw new Exception("need to create disk manager for "+newsGroup.groupName);
    }

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }
    while (destVec.size()>8) {
        destVec.remove(8);
    }

    String zingpat = (String) session.getAttribute("zingpat");
    String queueMsg = "("+NewsAction.getActionCount()+" tasks)";

    HashCounterIgnoreCase tagCache = new HashCounterIgnoreCase();
    ImageInfo.parsePathTags(tagCache, folder);


    JSONArray fileObjs = new JSONArray();
    int lastNum = 0;
    int count=0;
    for (NewsFile nf : files) {

        if (count++ > 1000) {
            //never serve more than 1000 files
            break;
        }
        JSONObject oneFile = new JSONObject();
        String fileName = nf.getFileName();
        oneFile.put("fileName", fileName);
        int seq = nf.getSequenceNumber();
        oneFile.put("fnNum", seq);
        oneFile.put("gap", seq != lastNum + 1);
        lastNum = seq;
        oneFile.put("fnPatt", nf.getPattern());

        File filePath = nf.getFilePath();
        DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePath);
        String localPath = dm.getOldRelativePathWithoutSlash(filePath);

        String bestName = nf.getFileName();
        File matchingFile = NewsFile.isInList(fileName, folderChildren);
        long fileSize = 0;
        if (matchingFile!=null){
            bestName = matchingFile.getName();
            fileSize = matchingFile.length();
        }
        oneFile.put("bestName", bestName);
        String bestPath = localPath;
        int fileNamePos = localPath.indexOf(fileName);
        if (fileNamePos>0) {
            bestPath = localPath.substring(0,fileNamePos) + bestName;
        }
        oneFile.put("bestPath", dm.diskName + "/" + bestPath);
        boolean needSave = folderExists && matchingFile==null;
        oneFile.put("needSave", needSave);
        oneFile.put("fileExists", matchingFile!=null);

        oneFile.put("isDownloading", nf.isMarkedDownloading());
        oneFile.put("isComplete", nf.isComplete());
        oneFile.put("isMapped", nf.isMapped());
        oneFile.put("fileSize", fileSize);
        oneFile.put("partsAvailable", nf.partsAvailable());
        oneFile.put("partsExpected", nf.partsExpected());
        oneFile.put("sampleArticle", nf.getSampleArticleNum());
        Exception e = nf.getFailMsg();
        if (e!=null) {
            oneFile.put("hadError", e.toString());
        }

        fileObjs.put(oneFile);
    }
    fileObjs.write(out, 2, 0);
%>