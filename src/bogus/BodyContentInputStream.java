package bogus;

import java.io.InputStream;
import java.io.IOException;


/**
* constructed on the raw message stream, this will skip all the header lines
* an stream the rest of the contents to the end of the contained stream.
*
* The header is terminated by a blank line ... that is, two newline bytes
* in a row.  So start reading and skipping until you get two newline bytes
* in a row, and then return all the following bytes like normal.
*/
class BodyContentInputStream extends InputStream
{
    private InputStream wrappedStream;
    private boolean headerSkipped = false;

    public BodyContentInputStream(InputStream is)
    {
        wrappedStream = is;
    }

    public int read() throws IOException
    {
        if (!headerSkipped)
        {
            boolean newLine = true;
            int ch = wrappedStream.read();
            while (ch>=0)
            {
                if (!newLine) {
                    //if not at the beginning of a line, skip everything
                    if (ch == '\n') {
                        newLine = true;
                    }
                }
                else if (ch == '\r') {
                    //ignore these pesky little things, without changing state
                }
                else if (ch == '\n') {
                    //this is it, this is the blank line, the second newline
                    headerSkipped = true;
                    return wrappedStream.read();
                }
                else {
                     newLine = false;
                }
                ch = wrappedStream.read();
            }

            //it only gets here if it never finds the end of the header...
            //so this is probably a -1
            return ch;
        }

        return wrappedStream.read();
    }

}
