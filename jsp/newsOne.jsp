<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.UtilityMethods"
%><%@page import="bogus.UUDecoderStream"
%><%@page import="bogus.YEnc"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.File"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession ns = newsGroup.session;

    String artno     = UtilityMethods.reqParam(request, "News One Page", "artno");
    String thisPage = "newsOne.jsp?artno="+URLEncoder.encode(artno, "UTF-8");
    long artnoInt = Long.parseLong(artno);
    NewsArticle art = (NewsArticle) newsGroup.getArticleOrNull(artnoInt);
    String headerSubj = art.getHeaderSubject();
    String encodedHeaderSubj = URLEncoder.encode(headerSubj.substring(0,8),"UTF-8");
%>
<html>
<body>
<h3>One News Article</h3>
<p><a href="news.jsp?search=<%UtilityMethods.writeURLEncoded(out, art.getDigest());%>">News</a></p>
<hr/>
<%
    if (art!=null)
    {
        NewsBunch npatt = newsGroup.getBunch(art.getDigest(), art.getFrom());
        String url = "newsDetail2.jsp?d="+URLEncoder.encode(art.getDigest(), "UTF-8")+"&f="+URLEncoder.encode(art.getFrom(), "UTF-8");
%>

<table><tr><td>article number: <%= art.getNumber()  %>
Get: </td><td><form action="newsFetch.jsp">
<input type="hidden" name="command" value="Refetch">
<input type="hidden" name="start" value="<%=artnoInt%>">
<input type="hidden" name="step" value="1">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out,thisPage);%>">
<input type="submit" name="count" value="20">
<input type="submit" name="count" value="40">
<input type="submit" name="count" value="60">
</form></td><td><form action="newsFetch.jsp">
<input type="hidden" name="command" value="Refetch">
<input type="hidden" name="start" value="<%=artnoInt-20%>">
<input type="hidden" name="step" value="1">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out,thisPage);%>">
<input type="hidden" name="count" value="20">
<input type="submit" name="xxx" value="-20">
</form></td></tr></table>
<ul>
<li> Article No: <%= art.getNumber() %>
    <a href="newsGaps.jsp?limit=100&begin=<%= art.getNumber() %>&thresh=10&step=10">Gaps</a>
    <a href="newsDump.jsp?artno=<%= art.getNumber() %>&high=<%=encodedHeaderSubj%>">Dump</a></li>
<li> Subject: <% HTMLWriter.writeHtml(out, art.getHeaderSubject()); %> </li>
<li> From: <% HTMLWriter.writeHtml(out, art.getHeaderFrom()); %> </li>
<li> Date: <% HTMLWriter.writeHtml(out, art.getHeaderDate()); %> </li>
<li> Digest: <a href="<%=url%>"><% HTMLWriter.writeHtml(out, art.getDigest() ); %></a> </li>
<li> Template: <% HTMLWriter.writeHtml(out, npatt.getTemplate() ); %> </li>
<li> FolderLoc: <% HTMLWriter.writeHtml(out, npatt.getFolderLoc() ); %> </li>
<li> Filled: <% HTMLWriter.writeHtml(out, art.getFileName()); %> </li>
</ul>
<hr/>
<%
         if (art.buffer==null) {
            %>Not loaded
            <form action="newsOneAction.jsp" method="get">
                <input type="hidden" name="artno" value="<%=artnoInt%>">
                <input type="submit" name="action" value="Read Article">
            </form><%
        }
        else {
            %><h2>Loaded <%=art.buffer.totalBytes()%> bytes. <a href="newsPict.jsp?artno=<%=artnoInt%>" target="images">Picture.jpg</a> </h2><pre><%
            InputStream is = art.buffer.getInputStream();
            streamABit(out, is, 300);

            %></pre><br/><hr/><h2>Body Content</h2><pre><%

            is = art.getBodyContent();
            streamABit(out, is, 300);

            %></pre><br/><hr/><h2>UUDecoded Content</h2><pre><%

            try {
                is = new UUDecoderStream(art.getBodyContent());
                streamABit(out, is, 300);
            }
            catch (Exception e) {
                 writeException(out, e);
            }

            %></pre><br/><hr/><h2>YEnc Decoded Content <a href="newsPict2.jsp?artno=<%=artnoInt%>" target="images">Picture.jpg</a></h2><pre><%

            try {
                is = art.getBodyContent();
                MemFile mf2 = new MemFile();
                OutputStream out2 = mf2.getOutputStream();
                YEnc y = new YEnc(is);
                y.doDecode(out2);
                out2.flush();
                InputStream is2 = mf2.getInputStream();
                out.write("name: "+y.fileName+"\n");
                out.write("sizeAtStart: "+y.sizeAtStart+"\n");
                out.write("sizeAtEnd: "+y.sizeAtEnd+"\n");
                out.write("totalOutput: "+y.totalOutput+"\n");
                out.write("partNo: "+y.partNo+"\n");
                out.write("partBegin: "+y.partBegin+"\n");
                out.write("partEnd: "+y.partEnd+"\n");
                if (y.isComplete) {
                    out.write("complete: yes\n");
                }
                else {
                    out.write("complete: no\n");
                }
                streamABit(out, is2, 300);
                //testIt(out, "tpsp", "JFIF");
                //testIt(out, ")\u0002)=J*", "sss");
                //testIt(out, ")\u0002)=J*:tpsp*++**+*+**)", "sss");
                //testIt(out, "\u0091\u008EW\u0094\u009A\u008F\u0091", "sss");
            }
            catch (Exception e) {
                 writeException(out, e);
            }

            %></pre><br/><hr/><h2>Raw Content</h2><pre><%
            InputStream r = art.buffer.getInputStream();
            streamABit(out, r, 3000000);

            %></pre><hr/> <%

            File testout = new File("c:\\temp\\sample.jpg");
            if (testout.exists()) {
                testout.delete();
            }
            try {
                FileOutputStream fos = new FileOutputStream(testout);
                art.streamDecodedContent(fos);
                fos.flush();
                fos.close();
            }
            catch (Exception e) {
                 writeException(out, e);
            }
        }
    }
%>
<hr/>
<table>
<%
    for (int i=0; i<256; i++) {
        int j=(i+42)%256;
        %>
        <tr><td><%
        writeChar(out, (char) i);
        %></td><td><%
        switch (j) {
            case 0: out.write("=@"); break;
            case '\t': out.write("=I"); break;
            case '\r': out.write("=M"); break;
            case '\n': out.write("=J"); break;
            case '=': out.write("=}"); break;
            default:writeChar(out, (char)j);
        }
        %></td></tr><%

    }
%>
</table>
</body>
</html>
<%!public void streamABit(Writer out, InputStream is, int len) throws Exception {
        int lineSize = 0;
        for (int i=0; i<len; i++) {
            int ch = is.read();
            if (ch<0) {
                return;
            }
            if (ch=='\r') {
                continue;  //really ignore these
            }
            if (ch=='\n') {
                out.write("\n");
                lineSize = 0;
                continue;
            }
            writeChar(out, (char) ch);
            if (lineSize++>=80) {
                out.write("$\n");
                lineSize = 0;
            }
        }
    }
    public void readABit(Writer out, Reader r, int len) throws Exception {
        int lineSize = 0;
        for (int i=0; i<len; i++) {
            int ch = r.read();
            if (ch=='\r') {
                continue;  //really ignore these
            }
            if (ch=='\n') {
                out.write("\n");
                lineSize = 0;
                continue;
            }
            writeChar(out, (char) ch);
            if (lineSize++>=80) {
                out.write("$\n");
                lineSize = 0;
            }
        }
    }


    public void testIt(Writer out, String inVal, String outVal) throws Exception  {

        MemFile mft = new MemFile();
        OutputStream os = mft.getOutputStream();
        writeBytes(os, "garbage\nup\nfront\n=ybegin  line=128 size="+outVal.length()+" name=001.jpg\n");
        writeBytes(os, inVal);
        writeBytes(os, "\n=yend size="+outVal.length()+"\ngarbage\nat\nend");
        os.flush();
        InputStream is = mft.getInputStream();
        MemFile mft2 = new MemFile();
        OutputStream os2 = mft2.getOutputStream();
        YEnc y = new YEnc(is);
        y.doDecode(os2);
        os2.flush();
        String result = getString(mft2.getInputStream());
        if (result.equals(outVal)) {
            out.write("<p>success </p>");
        }
        else {
            out.write("<p>failure <br/>  expected: ");
            writeStringHex(out, outVal);
            out.write("<br/>  received: ");
            writeStringHex(out, result);
            out.write("</p>");
        }
    }

    public void writeBytes(OutputStream os, String toSend) throws Exception
    {
        for (int i=0; i<toSend.length(); i++)
        {
            int ch = toSend.charAt(i)&0xFF;
            os.write(ch);
        }
    }

    public String getString(InputStream is) throws Exception
    {
        StringBuffer sb = new StringBuffer();
        int chin = is.read();
        while (chin>=0)
        {
            sb.append((char)chin);
            chin = is.read();
        }
        return sb.toString();
    }


    public void writeStringHex(Writer out, String s) throws Exception {
        for (int i=0; i<s.length(); i++) {
            writeChar(out, s.charAt(i));
        }
    }


    public void writeChar(Writer out, char ch) throws Exception  {
        if (ch>'~' || ch<' ') {
            out.write("[");
            out.write(hexDigit[((ch>>4)%16)]);
            out.write(hexDigit[(ch%16)]);
            out.write("]");
        }
        else {
            HTMLWriter.writeHtml(out, ""+((char) ch));
        }
    }

    char[] hexDigit = new char[]{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

    public void writeException(Writer out, Exception e) {
        Throwable t = e;
        while (t!=null) {
            try {
                out.write("<br/>");
                HTMLWriter.writeHtml(out, "> "+t.toString());
            }
            catch (Exception ignore) {}
            t = t.getCause();
        }
    }%>

