package bogus;

import java.io.File;
import java.io.Writer;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * represents a news group on a news server
 */

public class NewsActionDownloadAll extends NewsAction {
    NewsBunch seeker;
    Vector<String> alreadyTried = new Vector<String>();

    public NewsActionDownloadAll(NewsBunch _seeker) throws Exception {
        seeker = _seeker;
        File storeFile = seeker.getFolderPath();
        if (!storeFile.exists()) {
            storeFile.mkdirs();
        }
        if (!storeFile.exists()) {
            throw new JSONException("unable to create the folder: {0}",storeFile);
        }
        if (!seeker.hasTemplate()) {
            seeker.createFolderIfReasonable();
        }
        seeker.isDownloading = true;
        seeker.pState = NewsBunch.STATE_DOWNLOAD;
        seeker.touch();
    }

    /**
     * Convenient static method creates and queues an instance
     */
    public static void start(NewsBunch _seeker) throws Exception {
        NewsActionDownloadAll nada = new NewsActionDownloadAll(_seeker);
        nada.addToFrontOfMid();
    }


    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        if (!NewsGroup.connect) {
            //no connection, so cancel, and leave right away
            seeker.pState = NewsBunch.STATE_INTEREST;
            seeker.isSeeking = false;
            return;
        }

        seeker.touch();
        if (seeker.pState != NewsBunch.STATE_DOWNLOAD) {
            // newsPattern is no longer wanting seeking
            out.write("\nNewsGroup Download Cancelled: ");
            HTMLWriter.writeHtml(out, seeker.tokenFill());
            return;
        }

        out.write("\n");
        if (!seeker.hasFolder()) {
            throw new JSONException(
                    "must set the file storage folder on the NewsPattern in order to retrieve all message bodies.");
        }
        int scheduleCount = 0;
        List<NewsFile> files = seeker.getFiles();
        List<NewsFile> filteredSet = new Vector<NewsFile>();
        int downCount = 0;
        int skipCount = 0;
        int schedCount = 0;
        int totalCount = 0;

        for (NewsFile nf : files) {

            totalCount++;

            String fname = nf.getFileName();
            File newFile = nf.getFilePath();
            if (newFile.exists()) {
                downCount++;
                continue;
            }
            if (alreadyTried.contains(fname)) {
                skipCount++;
                continue;
            }
            filteredSet.add(nf);
            schedCount++;
        }

        out.write("\nScheduled " + schedCount + ", Skipped " + skipCount + ", Already Down: "
                + downCount + ", Total: " + totalCount + " of " + seeker.getTemplate());

        // now randomly read them out
        Random rand = new Random();
        while (filteredSet.size() > 0) {
            int gotcha = rand.nextInt(filteredSet.size());
            NewsFile nf = filteredSet.remove(gotcha);

            NewsActionDownloadFile nadf = new NewsActionDownloadFile(nf, true);
            nadf.addToFrontOfLow();
            alreadyTried.add(nf.getFileName());
            scheduleCount++;
        }
        seeker.isDownloading = false; // set this off

        // this turns the download off when all the available files
        // are down ... however, seeking might turn up more files ...
        // need a better check.
        if (scheduleCount == 0) {
            if (seeker.pState == NewsBunch.STATE_DOWNLOAD) {
                seeker.pState = NewsBunch.STATE_DOWNLOAD_DONE;
            }
        }
        else {
            // schedule the next step
            addToEndOfQueue();
        }
    }

    public String getStatusView() throws Exception {
        return "Download all from "+seeker.digest;
    }
    
    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
