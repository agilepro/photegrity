<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionDownloadPattern"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionDownloadFile"
%><%@page import="bogus.NewsActionSeekBunch"
%><%@page import="bogus.NewsActionSeekABit"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.LocalMapping"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.NewsActionFixDisk"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        response.setStatus(401);
        %>not logged in<%
        return;
    }

    try {

        NewsGroup newsGroup = NewsGroup.getCurrentGroup();
        if (newsGroup==null) {
            throw new Exception("newsgroup is not loaded");
        }
        String dig       = UtilityMethods.reqParam(request, "News Detail Action", "dig");
        String f         = UtilityMethods.reqParam(request, "News Detail Action", "f");
        NewsBunch bunch = newsGroup.getBunch(dig.trim(), f);
        if (bunch==null) {
            throw new Exception("Can't find a bunch for digest ("+dig+")");
        }


        String cmd       = UtilityMethods.reqParam(request, "News Detail Action", "cmd");
        String prefFolder= UtilityMethods.defParam(request, "prefFolder", null);
        boolean delAll = (UtilityMethods.defParam(request, "delAll", null)!=null);
        String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

        String go = "BOGUS VALUE";
        String newsPage = "BOGUS VALUE";

        Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
        if (destVec==null) {
            destVec = new Vector<String>();
            session.setAttribute("destVec", destVec);
        }


        String zingpat = (String) session.getAttribute("zingpat");
        if (zingpat==null) {
            zingpat="";
        }
        if (destVec.size()>0) {
            prefFolder = destVec.get(0);
        }
        boolean autoPath = (UtilityMethods.defParam(request, "autopath", null)!=null);


        if ("GetPatt".equals(cmd)) {

            List<NewsFile> fileList = bunch.getFiles();
            NewsFile nf = fileList.get(0);
            String pattern = ImageInfo.patternFromFileName(nf.getFileName());
            if (pattern.endsWith("!")) {
                pattern = pattern.substring(0,pattern.length()-1);
            }
            session.setAttribute("zingpat", pattern);
            out.write("Picked up pattern: "+pattern+".  ");
            //now flow through to the next option
            cmd="GetFolder";
        }
        if ("GetFolder".equals(cmd)) {
            String dest = bunch.getFolderLoc();
            int destSize = destVec.size();
            for (int i=0; i<destSize; i++) {
                if (dest.equalsIgnoreCase(destVec.get(i))) {
                    destVec.remove(i);
                    break;
                }
            }
            destVec.insertElementAt(dest, 0);
            out.write("Picked up folder: "+dest+".  ");
            return;
        }
        if ("DoubleExtent".equals(cmd)) {
            bunch.seekExtent = bunch.seekExtent * 2;
            out.write("Extent is set to: "+bunch.seekExtent+".  ");
            return;
        }
        if ("DeleteAllHide".equals(cmd)) {
            newsGroup.clearOutBunch(dig,f);
            for (NewsFile nfc : bunch.getFiles()) {
                nfc.deleteFile();
            }
            out.write("This bunch is set to be hidden.");
            return;
        }
        if ("GetABit".equals(cmd)) {
            setDefaults(bunch, request);
            NewsActionSeekABit nasp = new NewsActionSeekABit(bunch);
            nasp.addToFrontOfHigh();
            out.write("This bunch is set to get a few files.");
            return;
        }
        if ("SeekBunch".equals(cmd)) {
            NewsActionSeekBunch nasp = new NewsActionSeekBunch(bunch);
            nasp.addToFrontOfHigh();
            out.write("This bunch is set to be seeked.");
            return;
        }
        if ("MarkInterested".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            out.write("This bunch is set to be interested.");
            return;
        }
        if ("CancelInterest".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INITIAL;
            out.write("This bunch is set to be initial state.");
            return;
        }
        if ("CancelSeek".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            out.write("Seeking has been canceled.");
            return;
        }
        if ("DownloadAll".equals(cmd)) {
            setDefaults(bunch, request);
            NewsActionSeekBunch nasp = new NewsActionSeekBunch(bunch);
            nasp.addToFrontOfHigh();
            NewsActionDownloadAll nada = new NewsActionDownloadAll(bunch);
            nada.addToFrontOfMid();
            out.write("All files will be downloaded.");
            return;
        }
        if ("CancelDownload".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            out.write("Downloading is stopped.");
            return;
        }
        if ("MarkComplete".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_COMPLETE;
            out.write("This bunch is set to completed state.");
            return;
        }
        if ("ToggleShrink".equals(cmd)) {
            bunch.shrinkFiles = !bunch.shrinkFiles;
            out.write("This bunch shrink set to "+bunch.shrinkFiles);
            return;
        }
        if ("ToggleYEnc".equals(cmd)) {
            bunch.isYEnc = !bunch.isYEnc;
            out.write("This bunch YEnc set to "+bunch.isYEnc);
            return;
        }

        throw new Exception("Don't understand command '"+cmd+"'");
    }
    catch (Exception e) {
        response.setStatus(401);
        JSONObject jo = JSONException.convertToJSON(e, "listBunces");
        jo.write(out,2,2);
    }
%>
<%!

    public void setDefaults(NewsBunch bunch, HttpServletRequest request) throws Exception {
        if (!bunch.hasTemplate()) {
            String temp = UtilityMethods.defParam(request, "template", null);
            if (temp==null) {
                temp = bunch.getTemplate();
            }
            String templc = temp.toLowerCase();
            if (!templc.endsWith(".jpg")) {
                throw new Exception("file template must end with .jpg: got ("+temp+")");
            }
            bunch.changeTemplate(temp, false);
        }
        if (!bunch.hasFolder()) {
            bunch.createFolderIfReasonable();
        }
    }
%>
