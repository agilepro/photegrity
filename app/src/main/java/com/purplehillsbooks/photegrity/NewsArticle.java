package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Reader;
import java.io.Writer;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Vector;

import org.apache.commons.net.nntp.ArticleInfo;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.CSVHelper;
import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.streams.NullWriter;
import com.purplehillsbooks.streams.StreamHelper;

/**
 * represents a news article on a news server
 */
public class NewsArticle {
    // these are constants for getEncodingType()
    public static final int UNKNOWN_ENCODING = 0;
    public static final int UU_ENCODING = 1;
    public static final int YENC_ENCODING = 2;
    public static final int BASE64_ENCODING = 3;

    //public String groupName;
    public long articleNo;

    // for feedback in the UI
    public boolean isDownloading;
    
    //if we read this once, and then later read and find it different, mark this
    //so we can track where these changes happen.
    public boolean headersChanged = false;
    public Exception failMsg;

    NewsGroup group;
    private NewsBunch nBunch;

    private String dig = null;
    private List<String> fPrint = null;

    public MemFile buffer = null;

    private static String[] options = { "Subject:", "From:", "Date:" };

    private String headerSubject;
    private String headerFrom;
    private String headerDate;

    public NewsArticle(NewsGroup newGroup, long articleNumber, String _subject, String _from, String _date) throws Exception {
        if (newGroup == null) {
            throw new JSONException(
                    "Received a null newGroupName parameter to the NewsGroup constructor.");
        }
        group = newGroup;
        articleNo = articleNumber;
        headerSubject = _subject;
        headerFrom = _from;
        headerDate = _date;
        getBunch();
    }

    public void setSessionForThisArticle() throws Exception {
        group.setGroupOnSession();
        ArticleInfo pointer = new ArticleInfo();
        if (!NewsGroup.connect) {
            throw new JSONException("Can't setSessionForThisArticle because not connected.");
        }
        if (!NewsGroup.session.internalSelectArticle(articleNo, pointer)) {
            throw new JSONException("unable to access article " + articleNo);
        }
    }

    public long getNumber() {
        return articleNo;
    }

    public String getHeaderSubject() {
        return headerSubject;
    }

    public String getHeaderFrom() {
        return headerFrom;
    }

    public String getHeaderDate() {
        return headerDate;
    }

    public NewsBunch getBunch() throws Exception {
        if (nBunch == null) {
            String d = getDigest();
            String f = getHeaderFrom();
            nBunch = group.getBunch(d,f);
            if (nBunch == null) {
                throw new JSONException(
                        "For unknown reason, can not get a NewsBunch object for digest ({0},{1})", d, f);
            }
        }
        return nBunch;
    }

    public File getFilePath() throws Exception {
        if (!nBunch.hasFolder() || !nBunch.hasTemplate()) {
            return null;
        }
        File folder = nBunch.getFolderPath();
        FracturedFileName template = FracturedFileName.parseTemplate(nBunch.getTemplate());
        FracturedFileName filePath = this.fillFracturedTemplate(template, nBunch.getBias());
        String foundName = filePath.existsAs(folder);
        if (foundName!=null) {
            return new File(folder, foundName);
        }
        else {
            return new File(folder, filePath.getRegularName());
        }
    }

    public boolean isOnDisk() throws Exception {
        if (!nBunch.hasFolder()) {
            return false;
        }
        if (!nBunch.hasTemplate()) {
            return false;
        }
        File folder = nBunch.getFolderPath();
        FracturedFileName template = FracturedFileName.parseTemplate(nBunch.getTemplate());
        FracturedFileName realName = this.fillFracturedTemplate(template, nBunch.getBias());
        return (realName.existsAs(folder)!=null);
    }

    /**
     * Either the content is in memory, OR content on disk.
     */
    public boolean canServeContent() throws Exception {
        return (buffer != null || isOnDisk());
    }

    /**
     * Parses the header of the news article, keeping those header entries that
     * are designated in 'options'
     */
    public static String[] parseHeader(long artNo) throws Exception {
        System.out.println("HEADER - start "+artNo+" - "+(System.currentTimeMillis()%10000));
        if (!NewsGroup.connect) {
            throw new JSONException("Can't get the article when not connect.");
        }
        Reader msgReader = NewsGroup.session.getArticleHeader(artNo);
        String[] parsedValues = readHeader(msgReader);
        System.out.println("HEADER - finish "+artNo+" - "+(System.currentTimeMillis()%10000)+" - "+parsedValues[0]);
        return parsedValues;
    }
    
    private static String[] readHeader(Reader msgReader) throws Exception {
        long timeStart = System.currentTimeMillis();
        String[] parsedValues = new String[3];

        char[] buffer = new char[10000];
        int offset = 0;
        boolean gettingToken = true;
        boolean discardSpace = true;
        int valueIndex = -1;

        //technically, this is counting characters, not bytes, however I believe that
        //these characters are pure ASCII and there is a one to one, so count them as bytes
        long byteCount = 0;
        int ch = msgReader.read();
        while (ch >= 0) {
            byteCount++;
            if (ch == ':' && gettingToken) {
                // this is the case of finding the terminator of a token
                // set everything up to receive the value
                gettingToken = false;
                buffer[offset] = ':';
                valueIndex = findMatchingOption(buffer);
                offset = 0;
                discardSpace = true;
            }
            else if (ch == '\n') {

                if (!gettingToken && valueIndex >= 0) {
                    // trim spaces off the tail end
                    while (offset > 0 && buffer[offset - 1] == ' ') {
                        offset--;
                    }

                    parsedValues[valueIndex] = new String(buffer, 0, offset);
                }
                gettingToken = true;
                valueIndex = -1;
                offset = 0;
            }
            else if (ch == '\r') {
                // ignore these newline chars
            }
            else if (ch == ' ' && discardSpace) {
                // ignore space chars when discardSpace is true
            }
            else if (ch == '\t' && discardSpace) {
                // ignore space chars when discardSpace is true
            }
            else {
                // consumer the character placing it in the buffer
                buffer[offset++] = (char) ch;
                discardSpace = false;
            }

            ch = msgReader.read();
        }
        Stats.addStats(timeStart, byteCount, 0, System.currentTimeMillis()-timeStart);
        return parsedValues;
    }

    private static int findMatchingOption(char[] buffer) {
        int last = options.length;
        for (int testVal = 0; testVal < last; testVal++) {
            String tOpt = options[testVal];
            boolean found = true;
            for (int i = 0; i < tOpt.length(); i++) {
                if (tOpt.charAt(i) != buffer[i]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return testVal;
            }
        }
        return -1;
    }

    public static char special = '\u25A3';


    
    
    /**
     * Get a compressed version of the subject with the numbers removed.
     */
    public String getDigest() {
        if (dig != null) {
            return dig;
        }
        String subj = headerSubject;
        if (subj == null) {
            throw new RuntimeException("somehow the subj of this message is null");
        }

        //look for a 'pure' file size on the end
        int digitOnEnd = subj.length()-1;
        char ch = subj.charAt(digitOnEnd);
        while (digitOnEnd>0 && ch>='0' && ch<='9') {
            digitOnEnd--;
            ch = subj.charAt(digitOnEnd);
        }
        //digitOnEnd holds the position of last non-digit
        int numDigits = subj.length()-1-digitOnEnd;
        if (numDigits>4) {
            //if five or more digits on the end, strip off, must be file size
            subj = subj.substring(0,digitOnEnd+1).trim();
        }

        Vector<String> numVec = new Vector<String>();
        StringBuffer buf = new StringBuffer();
        boolean doingNumbers = false;
        int copyPos = 0;
        int numStart = 0;
        int subjectLen = subj.length();
        for (int i = 0; i < subjectLen; i++) {
            ch = subj.charAt(i);
            if (ch >= '0' && ch <= '9') {
                if (!doingNumbers) {
                    numStart = i;
                    doingNumbers = true;
                }
            }
            else {
                if (doingNumbers) {
                    if (i - 3 > numStart) {
                        numStart = i - 3; // max num size
                    }
                    buf.append(subj.substring(copyPos, numStart));
                    buf.append(special);
                    numVec.add(subj.substring(numStart, i));
                    copyPos = i;
                    doingNumbers = false;
                }
            }
        }
        // tail of the string
        if (doingNumbers) {
            if (subjectLen - 3 > numStart) {
                numStart = subjectLen - 3; // max num size
            }
            buf.append(subj.substring(copyPos, numStart));
            buf.append(special);
            numVec.add(subj.substring(numStart));
        }
        else {
            buf.append(subj.substring(copyPos));
        }

        //Remove [*K] and [1*K] if it exists on the end of the string
        removeOffEndIfPresent(buf, "[\u25A3K]");
        removeOffEndIfPresent(buf, "[1\u25A3K]");
        //remove   " #### bytes" off the end if there is any
        removeBytesOffEndIfPresent(buf);

        dig = buf.toString();
        fPrint = numVec;
        return dig;
    }

    public static void removeBytesOffEndIfPresent(StringBuffer buf) {
        if (stringEndsWith(buf, "bytes") || stringEndsWith(buf, "Bytes")) {
            int len = buf.length()-6;
            while (buf.charAt(len)==' ') {
                len--;
            }
            while (buf.charAt(len)=='\u25A3') {
                len--;
            }
            while (buf.charAt(len)>='0' && buf.charAt(len)<='9') {
                len--;
            }
            while (buf.charAt(len)==' ') {
                len--;
            }
            buf.delete(len+1, buf.length());
        }
    }

    public static void removeOffEndIfPresent(StringBuffer buf, String token) {
        int len = buf.length();
        if (stringEndsWith(buf, token)) {
            int pos = len-token.length();
            while (buf.charAt(pos-1)==' ') {
                pos--;
            }
            buf.delete(pos, len);
        }
    }

    public static boolean stringEndsWith(StringBuffer buf, String token) {
        int pos = buf.length() - token.length();
        if (pos<0) {
            //it can not match if the token is longer than the string!
            return false;
        }
        for (int i=0; i<token.length(); i++) {
            if (buf.charAt(pos+i)!=token.charAt(i)) {
                return false;
            }
        }
        return true;
    }

    public String fillTemplate(String template) throws Exception {
        int special = -2;
        if (nBunch.fileNumOffset != 0) {
            special = nBunch.getSpecialTokenIndex();
        }
        return fillTemplatePlus(template, special, nBunch.fileNumOffset);
    }
    private String fillTemplatePlus(String template, int specialIndex, int bias) throws Exception {
        if (fPrint == null) {
            getDigest();
        }
        StringBuffer res = new StringBuffer();
        boolean inToken = false;
        for (int i = 0; i < template.length(); i++) {

            char ch = template.charAt(i);

            if (inToken) {
                int idx = ch - '0';
                // a $a puts the article number in the file name, for desperate situations
                if (ch=='a') {
                    res.append(Long.toString(articleNo));
                }
                else if (ch=='b') {
                    res.append(headerFrom);
                }
                else if (ch=='c') {
                    res.append(Long.toString(articleNo/1000));
                }
                else if (ch=='d') {
                    res.append(sanitize(headerFrom));
                }
                else if (ch=='e') {
                    res.append(Long.toString(articleNo/10000));
                }
                else if (ch=='f') {
                    res.append(Long.toString(articleNo/100000));
                }
                else if (idx >= 0 && idx < fPrint.size()) {
                    if (idx!=specialIndex) {
                        res.append(fPrint.get(idx));
                    }
                    else {
                        //add one to the value because this is the 'plus one' case
                        int val = UtilityMethods.safeConvertInt(fPrint.get(idx)) + bias;
                        //pad out 01 thru 09 to two digits because usually when special option
                        //is used it needs to be only two digits.
                        if (val<10) {
                            res.append("0");
                        }
                        res.append(Integer.toString(val));
                    }
                }
                inToken = false;
            }
            else {
                if (ch == '$') {
                    inToken = true;
                }
                else {
                    res.append(ch);
                }
            }
        }
        return res.toString();
    }
    public FracturedFileName fillFracturedTemplate(FracturedFileName template, int bias) throws Exception {
        if (template==null) {
            throw new JSONException("ProgramLogicError: fillFracturedTemplate called with a null template");
        }
        FracturedFileName filled = new FracturedFileName();
        filled.prePart = fillTemplate(template.prePart);
        filled.tailPart = fillTemplate(template.tailPart);
        if (template.numPart.length()==2) {
            int index = UtilityMethods.safeConvertInt(template.numPart.substring(1,2));
            filled.numPart = getParam(index);
        }
        else {
            filled.numPart = "";
        }
        filled.biasTheNumber(bias);
        return filled;
    }
    
    public String sanitize(String src) {
        StringBuilder sb = new StringBuilder();
        for (int i=src.length()-1; i>=0; i--) {
            char ch = src.charAt(i);
            if ( (ch>='0' && ch<='9')
               || (ch>='a' && ch<='z')
               || (ch>='A' && ch<='Z')) {
                sb.append(ch);
            }
        }
        return sb.toString().toLowerCase();
    }

    public String getFileNameOrFail() throws Exception {
        if (nBunch == null) {
            throw new JSONException(
                    "Cant calculate the file name because this article does not have associated pattern object");
        }
        if (!nBunch.hasTemplate()) {
            throw new JSONException(
                    "Cant calculate the file name because pattern object has no file template");
        }
        return getFileName();
    }

    public String getFileName() throws Exception {
        if (nBunch == null || !nBunch.hasTemplate()) {
            return "";
        }
        //return fillTemplate(nBunch.getTemplate());
        return fillFracturedTemplate(nBunch.getFracTemplate(), nBunch.getBias()).toString();
    }

    public String getParam(int index) throws Exception {
        if (fPrint == null) {
            getDigest();
        }
        if (index >= 0 && index < fPrint.size()) {
            return fPrint.get(index);
        }
        return null;
    }
    
    public int getParamValue(int index) throws Exception {
        if (index >= 0 && index < fPrint.size()) {
            return UtilityMethods.safeConvertInt(fPrint.get(index));
        }
        return -1;
    }

    public int getMultiFileNumerator() throws Exception {
        int numIndex = nBunch.numerator;
        if (numIndex < 0) {
            return 0;
        }
        String numVal = getParam(numIndex);
        if (numVal == null) {
            return 0;
        }
        return UtilityMethods.safeConvertInt(numVal);
    }

    public int getMultiFileDenominator() throws Exception {
        int numIndex = nBunch.denominator;
        if (numIndex == 0) {
            return 0;
        }
        String numVal = getParam(numIndex);
        if (numVal == null) {
            return 0;
        }
        return UtilityMethods.safeConvertInt(numVal);
    }

    public void getMsgBody() throws Exception {
        long startTime = System.currentTimeMillis();
        if (buffer != null) {
            return;
        }
        setSessionForThisArticle();

        MemFile newFile = new MemFile();
        Reader msgReader = NewsGroup.session.getArticleBody(articleNo);
        OutputStream os = newFile.getOutputStream();
        int ch = msgReader.read();
        long byteCount = 0;
        while (ch > 0) {
            byteCount++;
            // for binary files, we need to preserve the 1 character to 1 byte
            // mapping!
            os.write((ch & 0xFF));
            ch = msgReader.read();
        }
        os.flush();
        // only assign if successful
        buffer = newFile;
        failMsg = null;
        Stats.addStats(startTime, byteCount, 0, System.currentTimeMillis()-startTime);
    }

    public void clearMsgBody() throws Exception {
        buffer = null;
        failMsg = null;
    }

    public InputStream getBodyContent() throws Exception {
        if (buffer == null) {
            throw new JSONException(
                    "body has not been read yet.  Do that before calling getBodyContent.");
        }
        return new BodyContentInputStream(buffer.getInputStream());
    }

    
    public Reader getHeaderFromBody() throws Exception {
        if (buffer == null) {
            throw new JSONException(
                    "body has not been read yet.  Do that before calling getBodyContent.");
        }
        return new BodyHeaderReader(buffer.getReader());
    }
    
    public boolean confirmHeadersFromBody(Writer out) throws Exception {
        String[] vals = readHeader(getHeaderFromBody());
        boolean ok = true;
        if (!headerSubject.equals(vals[0])) {
            out.write("\n*** HEADERS changed, fetched body will be ignored");
            out.write("\n*** Expecting: "+headerSubject);
            out.write("\n*** BODY had: "+vals[0]);
            //headerSubject = vals[0];
            headersChanged = true;
            ok = false;
        }
        if (!headerFrom.equals(vals[1])) {
            //headerFrom = vals[1];
            headersChanged = true;
            ok = false;
        }
        if (!headerDate.equals(vals[2])) {
            //headerDate = vals[2];
            headersChanged = true;
            ok = false;
        }
        return ok;
    }
    
    
    /**
     * Determine the encoding by looking at the body of the message.
     * (Which means this might download the body for you.)
     */
    public int getEncodingType() throws Exception {
        String subj = getHeaderSubject();
        if (subj.indexOf("yEnc") > 0) {
            return YENC_ENCODING;
        }
        if (buffer == null) {
        	getMsgBody();
        	confirmHeadersFromBody(new NullWriter());
        }
        InputStream is = getBodyContent();
        StringBuffer firstTwenty = new StringBuffer(22);
        for (int i=0; i<20; i++) {
        	int b = is.read();
        	firstTwenty.append((char)b);
        }
        if (firstTwenty.indexOf("=ybegin")>=0) {
        	return YENC_ENCODING;
        }
        if (firstTwenty.indexOf("begin 644")>=0) {
        	return UU_ENCODING;
        }
        return UNKNOWN_ENCODING;
    }

    public void streamDecodedContent(OutputStream os) throws Exception {
        if (buffer == null) {
            throw new JSONException(
                    "body has not been read yet.  Do that before calling streamDecodedContent.");
        }
        
        int encoding = getEncodingType();
        
        //if not able to figure out on our own, use the flag the user can set
        //to force YEnc
        if (encoding == UNKNOWN_ENCODING) {
        	if (nBunch.isYEnc) {
        		encoding = YENC_ENCODING;
        	}
        }
        
        if (encoding==YENC_ENCODING) {
            InputStream is = getBodyContent();
            YEnc.decode(is, os);
        }
        else {
            InputStream is = new UUDecoderStream(getBodyContent());
            StreamHelper.copyInputToOutput(is, os);
            is.close();
            os.flush();
        }
    }

    public void streamContentOrFile(OutputStream os) throws Exception {
        if (buffer != null) {
            streamDecodedContent(os);
        }
        else {
            File f = getFilePath();
            if (f == null) {
                throw new JSONException(
                        "No body content in memory, and can not stream from disk because the storage path or name template has not been set.");
            }
            InputStream is = new FileInputStream(f);
            byte[] buf = new byte[2048];
            int got = is.read(buf);
            while (got >= 0) {
                os.write(buf, 0, got);
                got = is.read(buf);
            }
            is.close();
        }
    }

    public void storeBufferToDisk() throws Exception {
        if (buffer == null) {
            throw new JSONException(
                    "ProgramLogicError: Can not store buffer to disk when there is no buffer!");
        }
        File f = getFilePath();
        if (f == null) {
            throw new JSONException(
                    "Can not store this buffer to disk because the storage path or name template has not been set.");
        }
        if (f.exists()) {
            // silently ignore requests when the file already exists
            return;
        }
        FileOutputStream fos = new FileOutputStream(f);
        streamDecodedContent(fos);
        fos.flush();
        fos.close();

        // there is no sense holding on to the buffer since the file is exactly
        // the same
        buffer = null;
    }

    public void writeCacheLine(Writer w) throws Exception {
        Vector<String> values = new Vector<String>();
        values.add(Long.toString(getNumber()));
        values.add(headerSubject);
        values.add(headerFrom);
        values.add(headerDate);
        CSVHelper.writeLine(w, values);
    }

    public static NewsArticle createFromLine(NewsGroup theGroup, List<String> values)
            throws Exception {
        if (values.size() < 4) {
            // bogus line
            return null;
        }
        long articleNumber = Long.parseLong(values.get(0));
        return new NewsArticle(theGroup, articleNumber, values.get(1), values.get(2), values.get(3));
    }

    public static void sortByDigest(List<NewsArticle> list) throws Exception {
        Collections.sort(list, new authSubComp());
    }

    /**
     * sorts by subject (digest) then subject, then from
     */
    static class authSubComp implements Comparator<NewsArticle> {
        public authSubComp() {

        }

        public int compare(NewsArticle o1, NewsArticle o2) {
            NewsArticle na1 = o1;
            NewsArticle na2 = o2;
            int val = na1.getDigest().compareTo(na2.getDigest());
            if (val != 0) {
                return val;
            }
            val = na1.getHeaderSubject().compareTo(na2.getHeaderSubject());
            if (val != 0) {
                return val;
            }
            val = na1.getHeaderFrom().compareTo(na2.getHeaderFrom());
            return val;
        }
    }

    public static void sortByNumber(List<NewsArticle> list) throws Exception {
        Collections.sort(list, new authNumComp());
    }

    /**
     * sorts by subject (digest) then subject, then from
     */
    static class authNumComp implements Comparator<NewsArticle> {
        public authNumComp() {

        }

        public int compare(NewsArticle o1, NewsArticle o2) {
            NewsArticle na1 = o1;
            NewsArticle na2 = o2;
            if (na1.articleNo > na2.articleNo) {
                return 1;
            }
            if (na1.articleNo < na2.articleNo) {
                return -1;
            }
            return 0;
        }
    }
    
    
    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("articleNo", this.articleNo);
        jo.put("from", this.getHeaderFrom());
        jo.put("date", this.getHeaderDate());
        jo.put("subject", this.getHeaderSubject());
        jo.put("dig", this.getDigest()); 
        jo.put("bunch", nBunch.getJSON()); 
        jo.put("isDownloading", this.isDownloading);
        jo.put("headersChanged", this.headersChanged);
        jo.put("fileName", this.getFileName());
        jo.put("viz", this.isOnDisk());
        File filePathX = this.getFilePath();
        if (filePathX!=null) {
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePathX);
            String localPath = dm.diskName + "/" + dm.getOldRelativePathWithoutSlash(filePathX);
            jo.put("localPath", localPath);
        }
        return jo;
    }

}
