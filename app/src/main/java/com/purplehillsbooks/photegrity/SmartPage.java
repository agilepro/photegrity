/*
 * Thumbnail.java (requires Java 1.2+)
 */
package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.URLEncoder;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.HTMLWriter;

@SuppressWarnings("serial")
public class SmartPage extends javax.servlet.http.HttpServlet {

    public void doGet(HttpServletRequest req, HttpServletResponse resp) {
        OutputStream out = null;
        try {

            HttpSession session = req.getSession();

            out = resp.getOutputStream();
            resp.setContentType("text/html");
            req.setCharacterEncoding("UTF-8");

            String servletPath = req.getServletPath();
            if (servletPath == null) {
                throw new JSONException("Hmmmmmmm, no servlet path???");
            }

            int depth = 0;
            int pos = servletPath.indexOf("/", 1);// skip the slash which is the
                                                    // first character
            while (pos > 0) {
                depth++;
                pos = servletPath.indexOf("/", pos + 1);
            }

            StringBuffer returnPathBuf = new StringBuffer();
            for (int i = 0; i < depth; i++) {
                returnPathBuf.append("../");
            }
            String retPath = returnPathBuf.toString();

            ServletContext sc = session.getServletContext();
            String fullPath = sc.getRealPath(servletPath);

            File theFile = new File(fullPath);
            String editUrl = retPath + "Edit.jsp?p=" + URLEncoder.encode(servletPath, "UTF8");

            if (!theFile.exists()) {
                Writer w = new OutputStreamWriter(out, "UTF-8");

                w.write("<html><body><h1>Page '");
                HTMLWriter.writeHtml(w, servletPath);
                w.write("' does not exist.  Why don't you <a href=\"");
                HTMLWriter.writeHtml(w, editUrl);
                w.write("\">create it</a>?");
                w.write("</h1></body></html>");
                w.flush();
                return;
            }

            FileInputStream fis = new FileInputStream(theFile);
            InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
            LineNumberReader lnr = new LineNumberReader(isr);
            Writer w = new OutputStreamWriter(out, "UTF-8");

            w.write("<html><body>");

            String line = lnr.readLine();
            while (line != null) {
                formatText(w, line);
                line = lnr.readLine();
            }
            fis.close();
            terminate(w);
            w.write("<hr/>");
            w.write("<p><a href=\"");
            HTMLWriter.writeHtml(w, editUrl);
            w.write("\">Edit</a> page ");
            HTMLWriter.writeHtml(w, servletPath);
            w.write("</p>");
            w.flush();
        }
        catch (Exception e) {
            try {
                resp.setContentType("text/html");
                if (out == null) {
                    out = resp.getOutputStream();
                }
                Writer w = new OutputStreamWriter(out);
                w.write("<html><body><ul><li>Exception: ");
                w.write(UtilityMethods.getErrorString(e));
                w.write("</ul></body></html>");
                w.flush();
            }
            catch (Exception eeeee) {
                // nothing we can do here...
            }
        }
    }

    final int NOTHING = 0;
    final int PARAGRAPH = 1;
    final int BULLET = 2;
    final int HEADER = 3;

    int majorState = 0;
    int majorLevel = 0;
    boolean isBold = false;
    boolean isItalic = false;

    public void formatText(Writer out, String line) throws Exception {
        // trim the trailing spaces
        while (line.endsWith(" ")) {
            line = line.substring(0, line.length() - 1);
        }
        if (line.length() == 0) {
            terminate(out);
        }
        else if (line.startsWith("!!!")) {
            startHeader(out, line, 3);
        }
        else if (line.startsWith("!!")) {
            startHeader(out, line, 2);
        }
        else if (line.startsWith("!")) {
            startHeader(out, line, 1);
        }
        else if (line.startsWith("***")) {
            startBullet(out, line, 3);
        }
        else if (line.startsWith("**")) {
            startBullet(out, line, 2);
        }
        else if (line.startsWith("*")) {
            startBullet(out, line, 1);
        }
        else if (line.startsWith("----")) {
            terminate(out);
            out.write("<hr>\n");
        }
        else if (line.startsWith(" ")) {
            // continue whatever mode there is
            scanForStyle(out, line);
        }
        else {
            if (majorState != PARAGRAPH) {
                startParagraph(out);
            }
            scanForStyle(out, line);
        }
    }

    public void terminate(Writer out) throws Exception {
        if (isBold) {
            out.write("</b>");
        }
        if (isItalic) {
            out.write("</i>");
        }
        if (majorState == NOTHING) {
        }
        else if (majorState == PARAGRAPH) {
            out.write("</p>\n");
        }
        else if (majorState == BULLET) {
            while (majorLevel > 0) {
                out.write("</ul>\n");
                majorLevel--;
            }
        }
        else if (majorState == HEADER) {
            switch (majorLevel) {
            case 1:
                out.write("</h3>");
                break;
            case 2:
                out.write("</h2>");
                break;
            case 3:
                out.write("</h1>");
                break;
            }
        }
        majorState = NOTHING;
        majorLevel = 0;
        isBold = false;
        isItalic = false;
    }

    public void startParagraph(Writer out) throws Exception {
        terminate(out);
        out.write("<p>\n");
        majorState = PARAGRAPH;
        majorLevel = 0;
    }

    public void startBullet(Writer out, String line, int level) throws Exception {
        if (majorState != BULLET) {
            terminate(out);
        }
        majorState = BULLET;
        while (majorLevel > level) {
            out.write("</ul>\n");
            majorLevel--;
        }
        while (majorLevel < level) {
            out.write("<ul>\n");
            majorLevel++;
        }
        out.write("<li>\n");
        scanForStyle(out, line.substring(level));
    }

    public void startHeader(Writer out, String line, int level) throws Exception {
        terminate(out);
        majorState = HEADER;
        majorLevel = level;
        switch (level) {
        case 1:
            out.write("<h3>");
            break;
        case 2:
            out.write("<h2>");
            break;
        case 3:
            out.write("<h1>");
            break;
        }
        scanForStyle(out, line.substring(level));
    }

    public void scanForStyle(Writer out, String line) throws Exception {
        int pos = 0;
        int last = line.length();
        while (pos < last) {
            char ch = line.charAt(pos);
            switch (ch) {
            case '[':

                int pos2 = line.indexOf(']', pos);
                if (pos2 > pos + 1) {
                    String linkURL = line.substring(pos + 1, pos2);
                    outputLink(out, linkURL);
                    pos = pos2 + 1;
                }
                else if (pos2 == pos + 1) {
                    pos = pos + 2;
                }
                else {
                    pos = pos + 1;
                }
                continue;
            case '_':
                if (line.charAt(pos + 1) == '_') {
                    pos += 2;
                    if (isBold) {
                        out.write("</b>");
                    }
                    else {
                        out.write("<b>");
                    }
                    isBold = !isBold;
                    continue;
                }
            case '\'':
                if (line.charAt(pos + 1) == '\'') {
                    pos += 2;
                    if (isItalic) {
                        out.write("</i>");
                    }
                    else {
                        out.write("<i>");
                    }
                    isItalic = !isItalic;
                    continue;
                }
            }
            out.write(ch);
            pos++;
        }
        out.write("\n");
    }

    public void outputLink(Writer out, String linkURL) throws Exception {
        int barPos = linkURL.indexOf("|");
        String linkName = linkURL;
        String linkAddr = linkURL;

        if (barPos >= 0) {
            linkName = linkURL.substring(0, barPos);
            linkAddr = linkURL.substring(barPos + 1);
        }
        boolean isExternal = linkAddr.startsWith("http");
        if (!isExternal) {
            linkAddr = sanitize(linkAddr) + ".sp";
        }
        out.write("<a href=\"");
        HTMLWriter.writeHtml(out, linkAddr);
        out.write("\">");
        HTMLWriter.writeHtml(out, linkName);
        out.write("</a>");
    }

    public String sanitize(String source) throws Exception {
        StringBuffer result = new StringBuffer();
        int last = source.length();
        for (int i = 0; i < last; i++) {
            char ch = source.charAt(i);
            if (ch >= 'a' && ch <= 'z') {
                result.append(ch);
            }
            else if (ch >= '0' && ch <= '9') {
                result.append(ch);
            }
            else if (ch >= 'A' && ch <= 'Z') {
                result.append((char) (ch + 32));
            }
            else if (ch == '_') {
                result.append(ch);
            }
            else if (ch == '-') {
                result.append(ch);
            }
        }
        return result.toString();
    }
}
