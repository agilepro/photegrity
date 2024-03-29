package com.purplehillsbooks.photegrity;

import java.io.InputStream;
import java.io.IOException;

public class UUDecoderStream extends InputStream {
    private String name;
    private int mode;

    private byte[] outBuffer; // cache of decoded bytes
    private int outSize = 0; // size of the cache
    private int index = 0; // index into the cache
    private byte[] inBuffer; // cache of decoded bytes
    private int inSize = 0; // size of the cache
    private boolean inputDone = false;
    private boolean gotPrefix = false;
    private boolean gotEnd = false;
    private InputStream lin;

    /**
     * Create a UUdecoder that decodes the specified input stream
     * 
     * @param in
     *            the input stream
     */
    public UUDecoderStream(InputStream in) {
        lin = in;
        outBuffer = new byte[45]; // max decoded chars in a line = 45
        inBuffer = new byte[200];
    }

    /**
     * Read the next decoded byte from this input stream. The byte is returned
     * as an <code>int</code> in the range <code>0</code> to <code>255</code>.
     * If no byte is available because the end of the stream has been reached,
     * the value <code>-1</code> is returned. This method blocks until input
     * data is available, the end of the stream is detected, or an exception is
     * thrown.
     * 
     * @return next byte of data, or <code>-1</code> if the end of stream is
     *         reached.
     * @exception IOException
     *                if an I/O error occurs.
     * @see java.io.FilterInputStream#in
     */

    public int read() throws IOException {
        if (index >= outSize) {
            readPrefix();
            if (!decode()) {
                return -1;
            }
        }
        return outBuffer[index++] & 0xff; // return lower byte
    }

    public boolean markSupported() {
        return false;
    }

    public int available() throws IOException {
        // This is only an estimate, since in.available()
        // might include CRLFs too ..
        return ((lin.available() * 3) / 4 + (outSize - index));
    }

    /**
     * Get the "name" field from the prefix. This is meant to be the pathname of
     * the decoded file
     * 
     * @return name of decoded file
     * @exception IOException
     *                if an I/O error occurs.
     */
    public String getName() throws IOException {
        readPrefix();
        return name;
    }

    /**
     * Get the "mode" field from the prefix. This is the permission mode of the
     * source file.
     * 
     * @return permission mode of source file
     * @exception IOException
     *                if an I/O error occurs.
     */
    public int getMode() throws IOException {
        readPrefix();
        return mode;
    }

    /**
     * UUencoded streams start off with the line: "begin <mode> <filename>"
     * Search for this prefix and gobble it up.
     */
    private void readPrefix() throws IOException {
        if (gotPrefix) { // already got the prefix
            return;
        }

        while (true) {
            if (inputDone) {
                throw new IOException(
                        "Unable to UUDecode this stream: did not find a 'begin' line.");

            }
            // read till we get the prefix: "begin MODE FILENAME"
            readOneLine(128);
            if (startsWith("begin")) {
                mode = getInt(6, 9);
                name = new String(inBuffer, 10, inSize);
                gotPrefix = true;
                return;
            }
        }
    }

    private boolean decode() throws IOException {
        if (gotEnd) {
            return false;
        }
        outSize = 0;
        inSize = 0;
        index = 0;

        // we only care about lines < 128 in length
        while (inSize == 0) {
            if (inputDone) {
                throw new IOException(
                        "Parsed the input stream to the end, but never found an 'end' line");
            }
            readOneLine(128);

            if (startsWith("end")) {
                gotEnd = true;
                return false;
            }
        }
        int count = inBuffer[0];
        if (count < ' ') {
            throw new IOException(
                    "Format error ...  received a line that started with a character  less than 32");
        }

        // The first character in a line is the number of original (not
        // the encoded atoms) characters in the line. Note that all the
        // code below has to handle the <SPACE> character that indicates
        // end of encoded stream.
        count = (count - ' ') & 0x3f;

        if (count == 0) {
            readOneLine(128);
            if (!startsWith("end")) {
                throw new IOException(
                        "Parsed the input stream to a ZERO line, but never found an 'end' line");
            }
            gotEnd = true;
            return false;
        }

        int need = ((count * 8) + 5) / 6;
        if (inSize < need + 1) {
            throw new IOException("Short buffer error: only have a line of '" + count
                    + "' chars and we think we need '" + need + "'");
        }

        int i = 1;
        /*
         * A correct uuencoder always encodes 3 characters at a time, even if
         * there aren't 3 characters left. But since some people out there have
         * broken uuencoders we handle the case where they don't include these
         * "unnecessary" characters.
         */
        while (outSize < count) {
            // continue decoding until we get 'count' decoded chars
            byte a = (byte) ((inBuffer[i++] - ' ') & 0x3f);
            byte b = (byte) ((inBuffer[i++] - ' ') & 0x3f);
            outBuffer[outSize++] = (byte) (((a << 2) & 0xfc) | ((b >>> 4) & 3));

            if (outSize < count) {
                a = b;
                b = (byte) ((inBuffer[i++] - ' ') & 0x3f);
                outBuffer[outSize++] = (byte) (((a << 4) & 0xf0) | ((b >>> 2) & 0xf));
            }

            if (outSize < count) {
                a = b;
                b = (byte) ((inBuffer[i++] - ' ') & 0x3f);
                outBuffer[outSize++] = (byte) (((a << 6) & 0xc0) | (b & 0x3f));
            }
        }
        return true;
    }

    /**
     * tells you if the input buffer starts with a particular string pattern
     * (assuming no encoding ... ascii only)
     */
    private boolean startsWith(String testStr) {
        for (int i = 0; i < testStr.length(); i++) {
            if ((inBuffer[i]) != (testStr.charAt(i))) {
                return false;
            }
        }
        return true;
    }

    /**
     * Look at a range of the input buffer, and return that as an integer value
     * ... no exceptions If it is not a number as all, it simply returns zero.
     */
    private int getInt(int start, int end) {
        int res = 0;
        for (int i = start; i < end; i++) {
            int ch = inBuffer[i];
            if (ch >= '0' && ch <= '9') {
                res = (res * 10) + ch - '0';
            }
        }
        return res;
    }

    /**
     * Skip to the end of the current line, and read the next line Read a line
     * containing only ASCII characters from the input stream. A line is
     * terminated by a CR or NL or CR-NL sequence. A common error is a CR-CR-NL
     * sequence, which will also terminate a line. The line terminator is not
     * returned as part of the returned String. Returns null if no data is
     * available.
     * <p>
     * 
     * This class is similar to the deprecated
     * <code>DataInputStream.readLine()</code>
     */
    public void readOneLine(int maxLineLen) throws IOException {
        if (maxLineLen > inBuffer.length) {
            throw new RuntimeException(
                    "Program Logic Error: asked for more characters than the size of the input buffer");
        }

        inSize = 0;
        int c1 = lin.read();

        // first, skip any returns or line feeds off the beginning
        while (c1 == '\n' || c1 == '\r') {
            c1 = lin.read();
        }

        // now we have a real character, start adding them to the inBuffer
        // until the next CR is seen.
        while (inSize < maxLineLen) {
            if (c1 < 0) {
                inputDone = true;
                return;
            }
            else if (c1 == '\n') {
                // Got NL, outa here.
                return;
            }
            else if (c1 == '\r') {
                // just ignore it
            }
            else {
                inBuffer[inSize++] = (byte) c1;
            }
            c1 = lin.read();
        }
    }

}
