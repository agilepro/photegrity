package bogus;

import java.io.Writer;

import com.purplehillsbooks.streams.HTMLWriter;

/**
 * schedules a file save at a time when the background tasks are doing nothing
 * else...
 */

public class NewsActionSave extends NewsAction {

    public NewsActionSave() throws Exception {
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        NewsGroup ng = NewsGroup.getCurrentGroup();
        out.write("\nSaving File ... ");
        HTMLWriter.writeHtml(out, ng.groupName);
        out.flush();
        ng.saveCache();
        out.write(" ... done");
    }

    public String getStatusView() throws Exception {
        return "Save index";
    }

}
