<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.Stats"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.io.PrintStream"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Stack"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%request.setCharacterEncoding("UTF-8");

    try{
        response.setContentType("text/plain;charset=UTF-8");
        long starttime = System.currentTimeMillis();

        String pageName = "news.jsp";

        if (session.getAttribute("userName") == null) {
            %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
            return;
        }

        NewsGroup newsGroup = NewsGroup.getCurrentGroup();

        boolean groupLoaded = (newsGroup.defaultDiskMgr!=null);

        String hide = UtilityMethods.defParam(request, "hide", null);
        if (hide!=null) {
            throw new Exception("Hide parameter is no longer used.");
        }
        String filter = UtilityMethods.defParam(request, "filter", null);
        if (filter==null) {
            throw new Exception("Filter parameter is now required");
        }
        int windowSize = UtilityMethods.defParamInt(request, "window", (int) newsGroup.displayWindow);
        //here we pass by global variable ... not good
        newsGroup.displayWindow = windowSize;

        String dMode = UtilityMethods.defParam(request, "dMode", null);
        if (dMode!=null) {
            throw new Exception("dMode parameter is no longer used.");
        }

        Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
        String zingFolder = "";
        if (destVec!=null && destVec.size()>0) {
            zingFolder = destVec.get(0);
        }
        String zingPat = (String) session.getAttribute("zingpat");
        if (zingPat==null) {
            zingPat="";
        }

        String sort = UtilityMethods.defParam(request, "sort", "patt");
        String sortPart = "";
        boolean showID = false;
        boolean showTime = false;
        boolean showCount = true;
        boolean showFile = false;
        boolean showPath = false;

        if (!groupLoaded) {
            throw new Exception("News Group is not loaded.");
        }

        //long position = newsGroup.nextFetch;
        String groupName = newsGroup.getName();

        List<NewsBunch> allPatts = newsGroup.getFilteredBunches(filter);

        //figure out the starting point
        int start = UtilityMethods.defParamInt(request, "start", 0);
        String search = UtilityMethods.defParam(request, "search", null);
        if (start<=0) {
            if (search!=null) {
                int i=0;
                for (NewsBunch seeker : allPatts) {
                    if (search.compareTo(seeker.digest)<=0) {
                        start = i;
                        break;
                    }
                    i++;
                }
            }
            else {
                search = "";
            }
            if (start>4) {
                //back up four places so it is not right at the top
                start = start - 4;
            }
            else {
                start = 0;
            }
        }
        else {
            NewsBunch top = allPatts.get(start);
            if (top!=null) {
                search = top.digest;
            }
            else {
                search = "";
            }
        }

        JSONArray allBunchList = new JSONArray();
        String groupDiskName = newsGroup.defaultDiskMgr.diskName;

        for (NewsBunch nbnch : allPatts)
        {
            JSONObject rec = nbnch.getJSON();
            if (!nbnch.hasFolder()) {
                rec.put("folderStyle", "folder0.gif");
            }
            else {
                String folderLoc = nbnch.getFolderLoc();
                if (folderLoc.startsWith(groupDiskName)) {
                    rec.put("folderStyle", "folder2.gif");
                }
                else {
                    rec.put("folderStyle", "folder.gif");
                }
            }
            boolean hasZing = false;
            boolean hasZingFolder = zingFolder.equals(nbnch.getFolderLoc());
            if (nbnch.hasTemplate()) {
                for (PosPat ppinst : nbnch.getPosPatList()) {
                    if (hasZingFolder && zingPat.equals(ppinst.getPattern())) {
                        hasZing = true;
                    }
                }
            }
            rec.put("hasZing", hasZing);
            allBunchList.put(rec);
        }

        //now, write all the records out to the stream
        allBunchList.write(out,2,0);
    }
    catch (Exception e) {
        response.setStatus(401);
        JSONObject jo = JSONException.convertToJSON(e, "listBunces");
        jo.write(out,2,2);
    }

%>
