<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsAction"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.Stats"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
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
        long windowMin = UtilityMethods.defParamLong(request, "min", newsGroup.lowestToDisplay);
        int windowSize = UtilityMethods.defParamInt(request, "window", (int) newsGroup.displayWindow);
        
        //here we pass by global variable ... not good
        newsGroup.displayWindow = windowSize;
        newsGroup.lowestToDisplay = windowMin;

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


        List<NewsBunch> allPatts = new Vector<NewsBunch>();
        
        String[] filterList = UtilityMethods.splitOnDelimiter(filter, ' ');
        
        for (NewsBunch tBunch : newsGroup.getAllBunches()) {
            if (tBunch.minId>windowMin+windowSize) {
                continue;
            }
            if (tBunch.maxId<windowMin) {
                continue;
            }
            if (determineFilter(filterList, tBunch)) {
                allPatts.add(tBunch);
            }
            //else if (tBunch.getSender().indexOf(filter)>=0) {
            //  allPatts.add(tBunch);
            //}
            //else if (tBunch.extraTags!=null && tBunch.extraTags.indexOf(filter)>=0) {
            //  allPatts.add(tBunch);
            //}
        }


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
            if (nbnch.maxId<windowMin) {
                continue;
            }
            if (nbnch.minId>windowMin+windowSize) {
                continue;
            }
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

        JSONObject ret = new JSONObject();
        ret.put("windowMin", windowMin);
        ret.put("windowSize", windowSize);
        ret.put("list", allBunchList);
        
        //now, write all the records out to the stream
        ret.write(out,2,0);
    }
    catch (Exception e) {
        response.setStatus(401);
        JSONObject jo = JSONException.convertToJSON(e, "listBunches"); 
        jo.write(out,2,2);
    }

%>
<%!

    public boolean determineFilter(String[] filterList, NewsBunch rec) throws Exception  {
        if (filterList==null || filterList.length==0) {
            return true;
        }
        for (String fitem : filterList) {
            if (fitem.startsWith("-")) {
                fitem = fitem.substring(1);
                if (rec.digest.indexOf(fitem) > -1) {
                    return false;
                }
                else if (rec.getTemplate().indexOf(fitem) > -1) {
                    return false;
                }
                else if (rec.getSender().indexOf(fitem) > -1) {
                    return false;
                }
                continue;
            }
            else {
                if (rec.digest.indexOf(fitem) > -1) {
                    continue;
                }
                else if (rec.getTemplate().indexOf(fitem) > -1) {
                    continue;
                }
                else if (rec.getSender().indexOf(fitem) > -1) {
                    continue;
                }
            }
            return false;
        }
        return true;
    }

%>
