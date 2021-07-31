package com.purplehillsbooks.photegrity;

import java.io.IOException;
import java.io.Reader;


/**
* constructed on the raw message stream, this will skip all the header lines
* an stream the rest of the contents to the end of the contained stream.
*
* The header is terminated by a blank line ... that is, two newline bytes
* in a row.  So start reading and skipping until you get two newline bytes
* in a row, and then return all the following bytes like normal.
*/
class BodyHeaderReader extends Reader {
    private Reader wrappedReader;
    private boolean headerDone = false;
    private boolean lastCharWasNewLine = false;

    public BodyHeaderReader(Reader r) {
        wrappedReader = r;
    }

    public int read() throws IOException {
        if (headerDone) {
            return -1;
        }
        int ch = wrappedReader.read();
        while (ch>=0) {
            if (ch == '\r') {
                //ignore these pesky little things, without changing state
            }
            else if (ch == '\n') {
                if (lastCharWasNewLine) {
                    headerDone = true;
                    return -1;
                }
                //this is it, this is the blank line, the second newline
                lastCharWasNewLine = true;
                return ch;
            }
            else {
                lastCharWasNewLine = false;
                return ch;
            }
            ch = wrappedReader.read();
        }
        headerDone = true;
        return -1;
    }
    
    public void close() throws IOException {
        wrappedReader.close();
    }

    @Override
    public int read(char[] buf, int offset, int length) throws IOException {
        int count = 0;
        for (int i=offset; i<offset+length; i++) {
            int thisChar = read();
            if (thisChar<0) {
                break;
            }
            else {
                buf[i] = (char) read();
                count++;
            }
        }
        return count;
    }

}
