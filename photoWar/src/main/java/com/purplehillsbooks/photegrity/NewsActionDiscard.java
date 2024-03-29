package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.Writer;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * schedules an action to (1) backup the current files, 
 * and then (2) discard articles in a particular range.
 */

public class NewsActionDiscard extends NewsAction {
    long rangeStart;
    long rangeEnd;

    public NewsActionDiscard(long _rangeStart, long _rangeEnd) throws Exception {
        rangeStart = _rangeStart;
        rangeEnd = _rangeEnd;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        try {
            NewsGroup ng = NewsGroup.getCurrentGroup();
            out.write("\nDISCARD: Saving Data Files ... ");
            ng.saveCache();
            
            File container = ng.containingFolder;
            File backupContainer = new File(container,"_backup");
            File backupFolder = new File(backupContainer, Long.toString(System.currentTimeMillis()));
            backupFolder.mkdirs();
            
            out.write("\nDISCARD: Backing Up Data to "+backupFolder);
            File errFile = new File(container, ng.groupName + ".err2");
            if (!errFile.exists()) {
                throw new JSONException("Don't understand why the error file does not exist: {0}",errFile);
            }
            File newsFile = new File(container, ng.groupName + ".news");
            if (!newsFile.exists()) {
                throw new JSONException("Don't understand why the news file does not exist: {0}",newsFile);
            }
            File pattFile = new File(container, ng.groupName + ".patt");
            if (!pattFile.exists()) {
                throw new JSONException("Don't understand why the bunches file does not exist: {0}",pattFile);
            }
            File localMapFile = new File(container, "newsLocalMap.csv");
            if (!localMapFile.exists()) {
                throw new JSONException("Don't understand why the pattern map file does not exist: {0}",localMapFile);
            }
           
            File errFileBack = new File(backupFolder, ng.groupName + ".err2");
            File newsFileBack = new File(backupFolder, ng.groupName + ".news");
            File pattFileBack = new File(backupFolder, ng.groupName + ".patt");
            File localMapFileBack = new File(backupFolder, "newsLocalMap.csv");
            
            //these will fail if the backup file already exists
            UtilityMethods.copyFileContents(errFile, errFileBack);
            UtilityMethods.copyFileContents(newsFile, newsFileBack);
            UtilityMethods.copyFileContents(pattFile, pattFileBack);
            UtilityMethods.copyFileContents(localMapFile, localMapFileBack);
            
            out.write("\nDISCARD: Removing articles from "+rangeStart+" to "+rangeEnd);
            ng.discardArticleRange(rangeStart, rangeEnd);
            
            out.write("\nDISCARD: Saving Again ... ");
            ng.saveCache();
            out.write("\nDISCARD: ... done");
            out.flush();
        }
        catch (Exception e) {
            throw new JSONException("Problem occurred discarding news articles {0} to {1}", e, rangeStart, rangeEnd);
        }
    }

    public String getStatusView() throws Exception {
        return "Discard news articles numbered "+rangeStart+" to "+rangeEnd;
    }
    
    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        jo.put("start", rangeStart);
        jo.put("end", rangeEnd);
        return jo;
    }

}
