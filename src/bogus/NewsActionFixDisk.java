package bogus;

import java.io.File;
import java.io.Writer;

import com.purplehillsbooks.json.JSONObject;

/**
 * Fixes the cashe in memory of what is on disk for a particular folder.
 * Everytime a file is moved in or out of a folder, this should be called
 * just to make sure everything is up to date.
 */

public class NewsActionFixDisk extends NewsAction {
    DiskMgr diskToLoad;
    File folder;

    public NewsActionFixDisk(DiskMgr dm, File folderPath) throws Exception {
        diskToLoad = dm;
        folder = folderPath;
    }

    /**
     * Refreshes the in memory cache for the disk/path without 
     * regard to the pattern ... all files in the folder are refreshed
     */
    public NewsActionFixDisk(PosPat pp) throws Exception {
        diskToLoad = pp.getDiskMgr();
        folder = pp.getFolderPath();
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        long startTime = System.currentTimeMillis();
        out.write("\nPreparing to refresh "+diskToLoad.diskName+":"+folder);
        out.flush();
        diskToLoad.refreshDiskFolder(folder);
        long secs = (System.currentTimeMillis()-startTime)/1000;
        out.write("\nTook "+secs+" seconds to refresh "+diskToLoad.diskName+":"+folder+" in .");
        out.flush();
    }

    public String getStatusView() throws Exception {
        return "Fixing the disk "+diskToLoad.diskName+":"+diskToLoad.getRelativePath(folder);
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
