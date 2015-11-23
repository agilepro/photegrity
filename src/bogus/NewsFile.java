package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Vector;

/**
 * represents a single file from a collection of news articles
 */

public class NewsFile {
    private Vector<NewsArticle> parts;
    private NewsBunch nBunch;
    private String fileName;
    private String pattern;
    private LocalMapping map;

    public NewsFile(String _fileName, NewsBunch _bnch) throws Exception {
        nBunch = _bnch;
        parts = new Vector<NewsArticle>();
        fileName = _fileName;
        String[] nameParts = NewsBunch.getFileNameParts(fileName);
        pattern = nameParts[0];
        refreshMapping();
    }
    
    public void refreshMapping() throws Exception {
    	if (parts.size()>0) {
	    	//check with the bunch again ... the template might have changed
	    	//this will get the file name from the template from the bunch
    		fileName = parts.elementAt(0).getFileName();
	    	//refresh the pattern from the file name
	        String[] nameParts = NewsBunch.getFileNameParts(fileName);
	        pattern = nameParts[0];
    	}
        PosPat whereIAm =  nBunch.getPosPat(pattern);
        map = LocalMapping.getMapping(whereIAm);
    }

    public void addArticle(NewsArticle art) {
        if (art == null) {
            throw new RuntimeException("Can not add a NULL article to a NewsFile");
        }
        parts.add(art);
    }

    public String getFileName() {
        return fileName;
    }
    public String getPattern() {
        return pattern;
    }

    /**
     * If this is a file in a set of files, this will return the index
     * number of that file
     */
    public int getSequenceNumber() {
        String[] fileNameParts = NewsBunch.getFileNameParts(fileName);
        int num = UtilityMethods.safeConvertInt(fileNameParts[1]);
        if (num == 0) {
            if (fileNameParts[2].contains("cover")) {
                return -100;
            }
            if (fileNameParts[2].contains("flogo")) {
                return -200;
            }
            if (fileNameParts[2].contains("sample")) {
                return -300;
            }
            return 0;
        }
        if (fileNameParts[2].endsWith("!")) {
            return 0 - num;
        }
        return num;
    }

    public NewsBunch getNewsBunch() {
        return nBunch;
    }

    
    public PosPat getPosPat() throws Exception {
    	if (map!=null) {
    		if (map.enabled) {
    			return map.dest;
    		}
    		else {
    			return map.source;
    		}
    	}
    	return nBunch.getPosPat(pattern);
    }

    public String getDiskName() throws Exception {
    	if (map!=null && map.enabled) {
    		return map.dest.getDiskMgr().diskName;
    	}
    	return nBunch.getDiskMgr().diskName;
    }
    
    /**
     * This is the permanent file position if a mapping
     * exists, and is enabled, and the local if no mapping exists,
     * or it is disabled.
     */
    public File getFilePath() throws Exception {
        File folder = nBunch.getFolderPath();
        if (folder==null) {
        	return null;  //probably never happens
        }
        if (map==null || !map.enabled) {
        	return new File(folder, fileName);
        }
    	String destFileName = map.dest.translateFileName(fileName);
        File destfolder = map.dest.getFolderPath();
        return new File(destfolder, destFileName);
    }

    /**
     * The temporary file is the file that exists in the new folder
     * This file should not exist if there is an active mapping
     * to a permanent file. 
     */
    public File getTempFilePath() {
        File folder = nBunch.getFolderPath();
        return new File(folder, fileName);
    }
    
    
    public int partsAvailable() {
        return parts.size();
    }

    public int partsExpected() throws Exception {
        if (parts.size() == 0) {
            return -1;
        }
        NewsArticle art0 = parts.get(0);
        return art0.getMultiFileDenominator();
    }

    public NewsArticle getPartOrFail(int num) throws Exception {
        if (parts.size() == 0) {
            // this should never happen
            throw new Exception("This NewsFile object has no articles at all in it");
        }
        int expect = partsExpected();

        // special case, you can always get first part if there is no numerator
        // or denominator
        if (expect <= 0) {
            return parts.get(0);
        }

        if (num > expect) {
            throw new Exception("Can not provide part #" + num + " when the file only has "
                    + expect + " parts.");
        }
        for (NewsArticle art : parts) {
            int partNo = art.getMultiFileNumerator();
            if (num == partNo) {
                return art;
            }
        }
        throw new Exception("Strange, did not find a part " + num + " even though there are "
                + parts.size() + " parts.");
    }

    public NewsArticle getPartOrNull(int num) throws Exception {
        if (parts.size() == 0) {
            return null;
        }
        int expect = partsExpected();

        // special case, you can always get first part if there is no numerator
        // or denominator
        if (expect <= 0) {
            return parts.get(0);
        }

        if (num > expect) {
            return null;
        }
        for (NewsArticle art : parts) {
            int partNo = art.getMultiFileNumerator();
            if (num == partNo) {
                return art;
            }
        }
        return null;
    }

    /**
     * Needs to check that each required part is there even if there are more
     * than one of some parts.
     */
    public boolean isComplete() throws Exception {
        if (parts.size() == 0) {
            return false;
        }
        NewsArticle art0 = parts.get(0);
        int num = art0.getMultiFileDenominator();
        if (parts.size() < num) {
            return false;
        }
        for (int i = 0; i < num; i++) {
            if (getPartOrNull(i + 1) == null) {
                return false;
            }
        }
        return true;
    }

    /**
     * throw an exception if the file is not complete
     */
    public void assertComplete() throws Exception {
        if (parts.size() == 0) {
        	throw new Exception("There are no parts at all for this file.");
        }
        NewsArticle art0 = parts.get(0);
        int num = art0.getMultiFileDenominator();
        if (parts.size() < num) {
        	throw new Exception("There are only "+parts.size()+" parts, expected "+num+" for this file.");
        }
        for (int i = 0; i < num; i++) {
            if (getPartOrNull(i + 1) == null) {
                throw new Exception("File part "+(i + 1)+" is missing from "+num+".");
            }
        }
    }

    public boolean isDownloaded() throws Exception {
        return (getFilePath().exists());
    }

    /**
     * returns true if there is a map that is enabled to put this 
     * file some place else.
     */
    public boolean isMapped() {
    	if (map==null) {
    		return false;
    	}
    	return map.enabled;
    }
    
    
    public void deleteFile() throws Exception {
        File content = getFilePath();
        if (content.exists()) {
            content.delete();
        }
        if (content.exists()) {
            throw new Exception("For some reason unable to delete file: " + content.toString());
        }
    }

    /**
     * Clear out and get rid of the memory copies. Usually called once the
     * content has been written to disk.
     */
    public void clearBodies() throws Exception {
        for (NewsArticle art : parts) {
            art.clearMsgBody();
        }
    }

    public void markDownloading() throws Exception {
        for (NewsArticle art : parts) {
            art.isDownloading = true;
        }
    }

    public void clearDownloading() throws Exception {
        for (NewsArticle art : parts) {
            art.isDownloading = false;
        }
    }

    public boolean isMarkedDownloading() throws Exception {
    	if (parts.size()==0) {
    		return false;
    	}
        NewsArticle art = parts.get(0);
        return art.isDownloading;
    }

    public static void sortByFileName(List<NewsFile> list) throws Exception {
        Collections.sort(list, new fileNameComp());
    }

    /**
     * sorts files by file name
     */
    static class fileNameComp implements Comparator<NewsFile> {
        public fileNameComp() {
        }

        public int compare(NewsFile o1, NewsFile o2) {
            NewsFile na1 = o1;
            NewsFile na2 = o2;
            return na1.getFileName().compareTo(na2.getFileName());
        }
    }

    /**
     * Give out a sample article
     */
    public NewsArticle getSampleArticle() throws Exception {
        for (NewsArticle art : parts) {
            return art;
        }
        return null;
    }

    /**
     * Seeking requires an article number to start with
     */
    public long getSampleArticleNum() throws Exception {
        for (NewsArticle art : parts) {
            return art.articleNo;
        }
        // this only happens on an empty file, which should be qutie rare
        throw new Exception(
                "This file does not have any associated articles, and so can't return any article numbers.");
    }

    
    public List<NewsArticle> getArticles() throws Exception {
    	return parts;
    }
    
    
    /**
     * This only changes the local, temp location and it
     * moves file if they are in the temp location
     * If a map entry maps them to a permanent place,
     * then they will simply be abandoned in that location.
     */
    public void renameFile(String oldTemplate, String newTemplate) throws Exception {
        if (parts.size() == 0) {
            return;
        }
        NewsArticle art = parts.get(0);
        String oldName = art.fillTemplate(oldTemplate);
        File oldPath = new File(nBunch.getFolderPath(), oldName);
        if (!oldPath.exists()) {
            return;
        }
        String newName = art.fillTemplate(newTemplate);
        File newPath = new File(nBunch.getFolderPath(), newName);
        if (newPath.exists()) {
            // just ignore it, don't move, don't delete
            return;
        }
        // oldPath.renameTo(newPath);

        ImageInfo ii = getImageInternal(true);
        if (ii==null) {
            throw new Exception("File exists, but ImageInfo is unable to find it: ("+oldPath+") for some unknown reason");
        }
        ii.renameFile(newName);

        // check to see if it really happened
        if (!newPath.exists()) {
            throw new Exception("expected to rename but destination does not exist: " + newPath);
        }
    }

    public void renameFileDeluxe(File srcFolder, String srcTemplate, boolean srcPlus,
                File destFolder, String destTemplate, boolean destPlus) throws Exception {

        if (parts.size() == 0) {
            //if for some reason there are no articles then we can't get the fingerprint
            return;
        }
        NewsArticle art = parts.get(0);

        int srcSpecial = -2;
        if (srcPlus) {
            srcSpecial = NewsBunch.findSpecialTokenIndex(srcTemplate);
        }
        int destSpecial = -2;
        if (destPlus) {
            destSpecial = NewsBunch.findSpecialTokenIndex(destTemplate);
        }

        String srcName = art.fillTemplatePlus(srcTemplate, srcSpecial);
        File srcPath = new File(srcFolder, srcName);
        if (!srcPath.exists()) {
            //nothing to move
            return;
        }
        String destName = art.fillTemplatePlus(destTemplate, destSpecial);
        File destPath = new File(destFolder, destName);
        if (destPath.exists()) {
            // just ignore it, don't move, don't delete
            return;
        }

        DiskMgr dm2 = DiskMgr.findDiskMgrFromPath(destPath);
        if (dm2==null) {
            throw new Exception("Not able to find a DM for: ("+destPath+")");
        }

        moveFileContents(srcPath, destPath);

        // check to see if it really happened
        if (srcPath.exists()) {
            throw new Exception("expected source file to be gone, but it is not: " + srcPath);
        }
        if (!destPath.exists()) {
            throw new Exception("expected to rename but destination does not exist: " + destPath);
        }
    }

    /**
     * Returns an image info only if one is loaded and in memory
     * otherwise returns null if the disk is not loaded.
     */
    public ImageInfo getImageInfo() throws Exception {
        return getImageInternal(false);
    }

    private ImageInfo getImageInternal(boolean fail) throws Exception {
        DiskMgr disk = nBunch.getDiskMgr();
        if (!disk.isLoaded) {
            return null;
        }
        String relPath = nBunch.getRelativePath();

        //There was a problem with paths ending with dot which is a noop when
        //the path is split into pieces.  Remove dots from the end before
        //looking them up...
        if (relPath.endsWith("./")) {
            relPath = relPath.substring(0,relPath.length()-2) + "/";
        }
        else if (relPath.endsWith(".")) {
            relPath = relPath.substring(0,relPath.length()-1) + "/";
        }
        else if (!relPath.endsWith("/")) {
            relPath = relPath + "/";
        }
        String parts[] = NewsBunch.getFileNameParts(fileName);
        String patternFromFile = parts[0];
        int val = UtilityMethods.safeConvertInt(parts[1]);
        if(parts[1].startsWith("!")) {
            //the number comes with the exclamation point, instead of a negative sign
            val = -val;
        }
        if (fileName.indexOf(".cover.")>0) {
            val = -100;
        }
        else if (fileName.indexOf(".flogo.")>0) {
            val = -200;
        }
        else if (fileName.indexOf(".sample.")>0) {
            val = -300;
        }
        List<ImageInfo> images = ImageInfo.findAllMatching(disk.diskName, relPath, patternFromFile, val);
        if (images.size()==0) {
            if (fail) {
                throw new Exception("Unable to find an image for "+disk.diskName+":"
                            +relPath+patternFromFile+"[val="+val+" or "+parts[1]+"]");
            }
            return null;
        }

        //just return an arbitrary one ... should be only one
        return images.get(0);
    }

    public void moveFile(DiskMgr newDiskMgr, String newSubPath, boolean deleteConflict)
            throws Exception {
        if (parts.size() == 0) {
            return;
        }
        if (!newSubPath.endsWith("/")) {
            newSubPath = newSubPath + "/";
        }

        // test that it is working:
        //DiskMgr oldDM = nBunch.getDiskMgr();

        File oldFolderPath = nBunch.getFolderPath();
        File newFolderPath = newDiskMgr.getFilePath(newSubPath);
    	System.out.println("NEWSFILE: Moving file ("+oldFolderPath+") to ("+newFolderPath+")");
        
        if (!oldFolderPath.exists()) {
            // we probably should not be here since there is nothing to move.
            throw new Exception("moveFile was called when the source folder (" + oldFolderPath
                    + ") does not exist .. probably an error");
        }
        if (!newFolderPath.exists()) {
            // we probably should not be here since the place to move to has not
            // been created
            throw new Exception("moveFile was called when the destination folder (" + newFolderPath
                    + ") does not exist .. probably an error");
        }
        if (oldFolderPath.equals(newFolderPath)) {
            throw new Exception("Apparently we are trying to move to old location: "
                    + newFolderPath);
        }

        File oldFilePath = new File(oldFolderPath, fileName);
        File newFilePath = new File(newFolderPath, fileName);
        if (!oldFilePath.exists()) {
        	throw new Exception("the source file "+oldFilePath+" does not exist, so there is no file to move! "+oldFilePath);
        }
        if (newFilePath.exists()) {
        	//so ... don't move it, just remove the old one
        	oldFilePath.delete();
        }
        else {
        	moveFileContents(oldFilePath, newFilePath);
        }
        
        // check to see if it really happened
        if (oldFilePath.exists()) {
            throw new Exception("expected source file to be gone, but it is not: " + oldFilePath);
        }
        if (!newFilePath.exists()) {
            throw new Exception("expected to rename but destination does not exist: " + newFilePath);
        }
    }
    
    
    
    public void setFailMsg(Exception e) {
        NewsArticle art = parts.get(0);
        art.failMsg = e;
    }

    public Exception getFailMsg() {
        for (NewsArticle art : parts) {
            if (art.failMsg != null) {
                return art.failMsg;
            }
        }
        return null;
    }

    /**
    * returns the file matching this file, or null if underspecified
    * or if it does not exist.
    */
    public File findMatchingFile() throws Exception {
        String fileName = getFileName();
        if (fileName==null) {
            return null;
        }
        File filePath = getFilePath();
        if (filePath==null) {
            return null;
        }
        File parentFolder = filePath.getParentFile();

        File[] folderChildren = parentFolder.listFiles();
        if (folderChildren==null) {
            return null;
        }

        return isInList(fileName, folderChildren);
    }

    /**
    * The file may not be an exact match, but instead may have tags or other
    * extensions.  This searches for a file that matches according to the rule
    * and returns the exact name fo the file.
    *
    * Second parameter needs  parentFolder.listFiles()   passed to it.
    * It is a little faster to use this if you are checking a lot of files
    * in the same parent folder.
    */
    public static File isInList(String fileName, File[] folderChildren) {

        if (folderChildren==null) {
        	//fix broken logic of system call.  Should never return null!
        	//folderChildren = new File[0];
        	return null;
        }
        String fileParts[] = NewsBunch.getFileNameParts(fileName);
        File bestFit = null;

        for (File aChild : folderChildren) {

            if (fileName.equalsIgnoreCase(aChild.getName())) {
                return aChild;
            }

            String childParts[] = NewsBunch.getFileNameParts(aChild.getName());

            if (fileParts[0].equalsIgnoreCase(childParts[0])) {
                int fileNum = safeConvertBang(fileParts[1]);
                int childNum = safeConvertBang(childParts[1]);
                if (fileNum==childNum && fileNum!=0) {
                    //don't do this for the zero, which includes cover, sample, etc
                    //also avoids bad matches in cases where there is no number
                    bestFit = aChild;
                }
            }
        }
        return bestFit;
    }

    /**
     * converts a string to an integer, but considers the exclamation mark
     * to indicate a negative value.
     */
    public static int safeConvertBang(String val){
        int intVal = UtilityMethods.safeConvertInt(val);
        if (val.indexOf('!')>=0) {
            intVal = 0 - intVal;
        }
        return intVal;
    }

    public static void moveFileContents(File oldFilePath, File newFilePath) throws Exception {
        
        FileInputStream fis = new FileInputStream(oldFilePath);
        FileOutputStream fos = new FileOutputStream(newFilePath);
        byte[] buff = new byte[8192];
        int amt = fis.read(buff);
        while (amt > 0) {
            fos.write(buff, 0, amt);
            amt = fis.read(buff);
        }
        fis.close();
        fos.close();
        oldFilePath.delete();
    }


}
