<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.Writer"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    String ss = request.getParameter("ss");  //source
    if (ss==null)
    {
        ss = "Sample";
    }
    String ds = request.getParameter("ds");  //destination
    if (ds==null)
    {
        ds = "kds_Fnzcyr";
    }
    String action = request.getParameter("action");  //button pressed

    String enc_ss = encrypt(ss);
    String dec_ds = decrypt(ds);
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Hasher</TITLE></HEAD>
<body>
<H1>Hasher</H1>
<hr/>
<form action="hasher.jsp" method="post">
<input type="text" name="ss" value="<%writeHtml(out, ss);%>" size="60">
<br/>
<input type="submit" name="action" value="Encrypt">
<pre>
<%writeHtml(out, enc_ss);%>
</pre>
<hr/>
<input type="text" name="ds" value="<%writeHtml(out, ds);%>" size="60">
<br/>
<input type="submit" name="action" value="Dencrypt">
<pre>
<%writeHtml(out, dec_ds);%>
</pre>
</form>

</body>
</HTML>


<%!

public String prefix = "kds_";

//this is a ROT13 cypher
public char[] mapchars = {'5','6','7', '8','9','0','1','2','3','4',
           'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
           'v', 'w', 'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e',
           'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm'};

public String encrypt(String val)
{
    String lcval = val.toLowerCase();
    StringBuffer res = new StringBuffer(prefix);
    int charPos = 0;
    int taken = 0;
    int max = val.length();
    while (charPos<max && taken<20)
    {
        char ch = lcval.charAt(charPos);
        char realChar = val.charAt(charPos);
        charPos++;
        if (ch<'0' || ch>'z')
        {
            continue;
        }
        if (ch>'9' && ch<'a')
        {
            continue;
        }
        int offset = 0;
        if (ch>='a' && ch<='z')
        {
            offset = ch-'a'+10;
        }
        else
        {
            offset = ch-'0';
        }

        char toChar = mapchars[offset];
        if (realChar>='A' && realChar<='Z')
        {
            toChar = (char) (toChar-32);
        }
        res.append(toChar);
        taken++;
    }
    return res.toString();
}

public String decrypt(String val)
{
    String lcval = val.toLowerCase();
    StringBuffer res = new StringBuffer();
    int charPos = 0;
    if (lcval.startsWith(prefix))
    {
        charPos = prefix.length();
    }
    int taken = 0;
    int curval = 0;
    int max = val.length();
    boolean isHigh = true;
    while (charPos < max)
    {
        char ch = val.charAt(charPos);
        boolean isUpper = false;
        if (ch>='A' && ch<='Z')
        {
            isUpper = true;
            ch = (char) (ch+' ');
        }
        charPos++;
        int offset = 0;
        for (int i=0; i<36; i++)
        {
            if (ch==mapchars[i])
            {
                offset = i;
            }
        }
        if (offset<10)
        {
            res.append((char) (offset+'0'));
        }
        else if (isUpper)
        {
            res.append(' ');
            res.append((char) (offset+'A'-10));
        }
        else
        {
            res.append((char) (offset+'a'-10));
        }
    }
    return res.toString();
}

public static void writeHtml(Writer out, String t) throws Exception {
    HTMLWriter.writeHtml(out, t);
}

%>