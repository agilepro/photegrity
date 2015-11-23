package bogus;

import java.io.Writer;

import org.workcast.streams.HTMLWriter;

/**
 * represents a news group on a news server
 */

public class NewsActionSpectrum extends NewsAction {
    int count = 100;
    int progress = 0;

    public NewsActionSpectrum(int _count) throws Exception {
        count = _count;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        NewsGroup newsGroup = NewsGroup.getCurrentGroup();
        int totalFails = 0;
        out.write("\nSTARTING READING");
        for (int k = 0; k < count; k++) {
        	progress = k;
            try {
                out.write("\n(");
                out.write(Integer.toString(newsGroup.step));
                out.write("/");
                out.write(Integer.toString(newsGroup.phase));
                out.write(")  - ");
                long val = newsGroup.takePhaseStep();
                out.write(Long.toString(val));
            }
            catch (Exception e) {
                out.write(" Exception ");
                out.write(Integer.toString(newsGroup.failCount));
                out.write(": ");
                HTMLWriter.writeHtml(out, UtilityMethods.getErrorString(e));
                if (++totalFails > 20) {
                    throw new Exception("too many failures.", e);
                }
            }
            out.flush();
        }
        out.write("\nCompleted Reading for now.....");
        out.flush();

        newsGroup.recalcStats();
        newsGroup.sortArticles();
    }

    public String getStatusView() throws Exception {
        return "Spectrum "+progress+"/"+count;
    }

}
