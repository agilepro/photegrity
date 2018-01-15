package bogus;

import java.io.File;
import java.io.Writer;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * represents a news group on a news server
 */

public class NewsActionDownloadOne extends NewsAction {
    NewsArticle art;

    public NewsActionDownloadOne(NewsArticle _art) throws Exception {
        art = _art;
        art.isDownloading = true;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        //if we have no connection, then don't try to download
        if (!NewsGroup.connect) {
            art.isDownloading = false;
            return;
        }

        out.write("\n<p>");
        try {
            HTMLWriter.writeHtml(out, art.getHeaderSubject());
            if (art.buffer == null) {
                out.write(" downloading... ");
                out.flush();
                art.getMsgBody();
            }
            if (art.getMultiFileDenominator() > 1) {
                out.write(" can't store part of a multipart");
            }
            else if (art.buffer != null) {
                File f = art.getFilePath();
                if (f != null && !f.exists()) {
                    out.write(" storing... " + f.toString());
                    out.flush();
                    art.storeBufferToDisk();
                }
                else {
                    out.write(" can't store ");
                }
            }
            out.write("\n</p>");
            out.flush();
            art.getBunch().touch();
        }
        finally {
            art.isDownloading = false;
        }
    }

    public String getStatusView() throws Exception {
        return "Download one article "+art.getFileName();
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
