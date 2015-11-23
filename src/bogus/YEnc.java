/*
 * YEnc.java
 *
 * parses a YEnc encoded stream
 */

package bogus;


import java.io.*;


public class YEnc
{
    private byte[] inBuffer;  // cache of decoded bytes
    private int inSize = 0;   // size of the cache
    private byte[] outBuffer;  // cache of decoded bytes
    private int outSize = 0;   // size of the cache
    private boolean gotPrefix = false;
    private boolean inputDone = false;
    private InputStream lin;

    //these values found in headers
    public String fileName;
    public int lineMax = 0;
    public int sizeAtStart = 0;
    public int sizeAtEnd = 0;
    public int partNo = 0;
    public int partBegin = 0;
    public int partEnd = 0;
    public boolean isComplete = false;
    public int totalOutput = 0;   // cumulative number of output bytes

    public static boolean decode(InputStream source, OutputStream destination) throws Exception
    {
        YEnc y = new YEnc(source);
        return y.doDecode(destination);
    }


    public YEnc(InputStream source) {
        lin = source;
        inBuffer = new byte[200];
        outBuffer = new byte[200];
        inSize = 0;
    }


    public boolean doDecode(OutputStream destination) throws Exception {
        try {
            readPrefix();

            boolean escape = false;
            while (readOneLine(150)) {
                if (startsWith("=yend")) {
                    //this is the termination criteria
                    sizeAtEnd = getFieldInt("size");
                    isComplete = (sizeAtEnd==sizeAtStart);
                    break;
                }
                if (startsWith("=ypart")) {
                    partBegin = getFieldInt("begin");
                    partEnd = getFieldInt("end");
                    continue;
                }
                outSize = 0;
                for (int i = 0; i < inSize; i++) {
                    int ch = ((int)inBuffer[i])&0xFF;
                    if (ch<0) {
                        throw new Exception("calculation incorrect, did not get unsigned value");
                    }
                    if (escape) {
                        outBuffer[outSize++] = (byte)((ch - 106 + 256)&0xFF);
                        escape = false;
                    }
                    else if ('=' == ch) {
                        escape = true;
                    }
                    else {
                        outBuffer[outSize++] = (byte)((ch - 42 + 256)&0xFF);
                    }
                }
                destination.write(outBuffer, 0, outSize);
                destination.flush();
                totalOutput += outSize;
            }
        }
        catch (Exception ioe)  {
            throw new Exception("Unable to complete the YEnc decoding", ioe);
        }
        return true;
    }

    /**
     * yEnc always starts with:
     * =ybegin line=128 size=123456 name=mybinary.dat
     * This method reads and skips lines until it finds one with this in it
     */
    private void readPrefix() throws Exception
    {
        if (gotPrefix) { // already got the prefix
            return;
        }

        while (readOneLine(150)) {
            // read till we get the prefix: "begin MODE FILENAME"
            if (startsWith("=ybegin")) {
                gotPrefix = true;
                fileName = getFieldValue("name", true);
                lineMax = getFieldInt("line");
                sizeAtStart = getFieldInt("size");
                partNo = getFieldInt("part");
                return;
            }
        }
        if (inputDone) {
            throw new IOException("Unable to yEnc decode this stream: did not find a '=ybegin' line.");

        }
    }
    /**
    * tells you if the input buffer starts with a particular string pattern
    * (assuming no encoding ... ascii only)
    */
    private boolean startsWith(String testStr)
    {
        for (int i=0; i<testStr.length(); i++)
        {
            if (((int)inBuffer[i]) != ((int)testStr.charAt(i))) {
                return false;
            }
        }
        return true;
    }


    /**
    * tells you the offset in the currently read line
    * of the specified ASCII string value
    */
    private int indexOf(String testStr)
    {
        int lastPossibleStart = inSize-testStr.length();
        for (int index=0; index<lastPossibleStart; index++)
        {
            boolean found = true;
            for (int j=0; j<testStr.length(); j++) {
                int ch = inBuffer[index+j] & 0xFF;
                if (ch != testStr.charAt(j)) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return index;
            }
        }
        return -1;
    }


    /**
    * finds a name/value pair in the line of bytes
    * looking for "file=abcdef.jpg" (followed by space or end of line)
    * if allowSpace is false, the value is terminated by space
    * if allowSpace is true, it will read all the way to the end of the line
    */
    private String getFieldValue(String fieldName, boolean allowSpace)
    {
        int namePos = indexOf(fieldName);
        if (namePos<0) {
            return null;
        }
        int index = namePos + fieldName.length();
        if (index>=inSize) {
            return null;
        }

        if (inBuffer[index]!='=') {
            return null;
        }

        //the value is now everything up to the next delimiter, either space or end of line
        StringBuffer res = new StringBuffer();
        while (++index<inSize) {
            int ch = ((int)inBuffer[index]) & 0xFF;
            if (ch==' ' && !allowSpace) {
                break;
            }
            res.append((char)ch);
        }

        return res.toString();
    }

    /**
    * finds a name/value pair in the line of bytes
    * looking for "file=abcdef.jpg" (followed by space or end of line)
    * if allowSpace is false, the value is terminated by space
    * if allowSpace is true, it will read all the way to the end of the line
    */
    private int getFieldInt(String fieldName)
    {
        int namePos = indexOf(fieldName);
        if (namePos<0) {
            return 0;
        }
        int index = namePos + fieldName.length();
        if (index>=inSize) {
            return 0;
        }

        if (inBuffer[index]!='=') {
            return 0;
        }

        //the value is now everything up to the next delimiter, either space or end of line
        int res = 0;
        while (++index<inSize) {
            int ch = (int)inBuffer[index] & 0xFF;
            if (ch<'0' || ch>'9') {
                break;
            }
            res = res*10 + ch - '0';
        }

        return res;
    }

    /**
     * Skip to the end of the current line, and read the next line
     * Read a line containing only ASCII characters from the input
     * stream. A line is terminated by a CR or NL or CR-NL sequence.
     * A common error is a CR-CR-NL sequence, which will also terminate
     * a line.
     * The line terminator is not returned as part of the returned
     * String. Returns null if no data is available. <p>
     *
     * This class is similar to the deprecated
     * <code>DataInputStream.readLine()</code>
     */
    public boolean readOneLine(int maxLineLen) throws Exception
    {
        if (maxLineLen > inBuffer.length) {
            throw new RuntimeException("Program Logic Error: asked for more characters than the size of the input buffer");
        }

        inSize = 0;
        int c1 = lin.read();
        if (c1<0) {
            if (c1<-1) {
                throw new Exception("Calculation error, got a value less than negative 1");
            }
            inputDone = true;
            return false;
        }

        //first, skip any returns or line feeds off the beginning
        while (c1 == '\n' || c1 == '\r')  {
            c1 = lin.read();
        }

        //now we have a real character, start adding them to the inBuffer
        //until the next CR is seen.
        while(inSize<maxLineLen) {
            if (c1<0) {
                if (c1<-1) {
                    throw new Exception("Calculation error, got a value less than negative 1");
                }
                inputDone = true;
                return (inSize>0);
            }
            if (c1 == '\n') {
                // Got NL, outa here.
                return true;
            }
            else if (c1 == '\r') {
                //just ignore it
            }
            else {
                inBuffer[inSize++] = (byte) c1;
            }
            c1 = lin.read();
        }

        return true;
    }

}
