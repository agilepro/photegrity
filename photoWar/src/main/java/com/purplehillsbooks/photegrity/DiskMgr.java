package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Properties;
import java.util.Set;
import java.util.Vector;

import javax.servlet.ServletContext;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class DiskMgr {
    public String diskName;
    public String diskNameLowerCase;

    public File mainFolder;    //root of the 'disk'
    public String mainPath;    //this is a string with the slashes the right way
    
    public boolean loadingNow = false;
    public boolean isChanged = false;

    public int extraCount = 0;
    public long extraSize = 0;


    public HashCounter allSymbolCnts = null;
    public HashCounterIgnoreCase allTagCnts = null;
    public HashCounter allPattCnts = null;

    //across all disks
    public static HashCounter globalSymbolCnts = null;
    public static HashCounterIgnoreCase globalTagCnts = null;
    public static HashCounter globalPattCnts = null;
    
    private static Hashtable<String, DiskMgr> diskList = null;
    private static Vector<File> newsFiles = null;

    /**
     * This is a list of paths separated by semicolons of all the places to look
     * for directories of photos
     */
    private static File rootFolder;
    public static File thumbPath;   // archive + slash + thumbs + slash

    public static List<String> masterGroups = new Vector<String>();

    
    public static void initPhotoServer(ServletContext sc) throws Exception {
        
        String configPath = sc.getRealPath("/config.txt");

        File f = new File(configPath);
        if (!f.exists()) {
            throw new JSONException("Did not find file '{0}'", f.getAbsolutePath());
        }
        FileInputStream fis = new FileInputStream(f);
        Properties props = new Properties();
        props.load(fis);

        String dbdir = (String) props.get("DBDir");
        rootFolder = new File(dbdir);
        if (!rootFolder.exists()) {
            throw new Exception("The main root data folder does not exist: "+rootFolder.getAbsolutePath());
        }
        thumbPath = new File(rootFolder,"thumbs");
        if (!thumbPath.exists()) {
            thumbPath.mkdir();
        }
        
        if (true) {
            File defaultFolder = new File(rootFolder, "news");
            NewsGroup ng = NewsGroup.getCurrentGroup();
            if (ng.containingFolder==null) {
                //if no news groups is really open, then we have to give it something
                ng.containingFolder = defaultFolder;
            }
            NewsBackground.startNewsThread(ng.containingFolder);
        }
        
        //this forces the construction of all the disk managers
        getDiskList();
        
        globalSymbolCnts = new HashCounter();
        globalTagCnts    = new HashCounterIgnoreCase();
        globalPattCnts   = new HashCounter();
        
        for (String diskName : diskList.keySet()) {
            DiskMgr oneMgr = diskList.get(diskName);
            globalSymbolCnts.addAll(oneMgr.allSymbolCnts);
            globalTagCnts.addAll(oneMgr.allTagCnts);
            globalPattCnts.addAll(oneMgr.allPattCnts);
        }
        
        masterGroups = globalTagCnts.sortedKeys();
    }
    
    public static boolean isInitialized() {
        return (rootFolder!=null && rootFolder.exists());
    }
    public static void assertInitialized() throws Exception {
        if (!isInitialized()) {
            throw new JSONException("Program Logic Error: DiskMgr class is not initialized at this time.");
        }
    }

    
    
    public DiskMgr(File diskPath) throws Exception {
        try {
            if (!rootFolder.exists()) {
                //not globally initialized yet
                throw new JSONException("Root folder has to exist: "+ rootFolder.getAbsolutePath());
            }
            if (!diskPath.exists()) {
                throw new JSONException("Attempt to create a DiskMgr on path that does not exist: ({0})",mainFolder.toString());
            }
            
            mainFolder = diskPath;
            diskName = diskPath.getName();
            diskNameLowerCase = diskName.toLowerCase();
            
            mainPath = mainFolder.getAbsolutePath().replace('\\', '/');
            if (!mainPath.endsWith("/")) {
                mainPath = mainPath + "/";
            }

            
            // determine if there is an extra directory, and if so complain about it
            //TODO: remove this once sure all archives are up to date and don't have extra folder
            File extraFolder = new File(mainFolder, "extra");
            if (extraFolder.exists()) {
                throw new Exception("Appears to be an disk archive with an OUTDATED extra folder in it  . . . eliminate this from : "+this.diskName);
            }
            
            System.out.println("--Constructing DiskMgr ("+mainFolder+") at ("+(new Date())+")");

/*
            File f1 = new File(mainFolder,"stats.txt");
            if (f1.exists()) {
                FileReader fr = new FileReader(f1);
                LineNumberReader lnr = new LineNumberReader(fr);

                lnr.readLine(); //old diskcount value, is always 0 now
                lnr.readLine(); //old diskSize value, is always 0 now
                extraCount = Integer.parseInt(lnr.readLine());
                extraSize = Long.parseLong(lnr.readLine());
                fr.close();
            }
            */

            /*
            HashCounterIgnoreCase allPosPat = new HashCounterIgnoreCase();
            allPosPat.loadFromFile(new File(mainFolder, "posPat.txt"));
            for (String key : allPosPat.keySet()) {
                int afterSlash = key.lastIndexOf("/")+1;
                if (afterSlash<1) {
                    //corrupted value?  ignore it?
                    continue;
                }
                PosPat pp = PosPat.addWithoutSorting(this, key.substring(0,afterSlash), key.substring(afterSlash));
                pp.setImageCount(allPosPat.getCount(key));
            }
            PosPat.sortIndex();
            */
            
            allSymbolCnts = new HashCounter();
            allTagCnts    = new HashCounterIgnoreCase();
            allPattCnts   = new HashCounter();
            
            MongoDB mongo = new MongoDB();
            mongo.findStatsForDisk(diskName, allTagCnts, allPattCnts, allSymbolCnts);
            mongo.close();
            
            String simpleKey = diskNameLowerCase;
            int dotPos = simpleKey.indexOf(".");
            if (dotPos>0) {
                simpleKey = simpleKey.substring(0,dotPos);
            }
            extraCount = allTagCnts.getCount(simpleKey);
            System.out.println("    set extraCount to "+extraCount);
        }
        catch (Exception e) {
            throw new JSONException("Can't construct a DiskMgr object for {0}",e,diskPath.getAbsolutePath());
        }
    }

    public static List<DiskMgr> getAllDiskMgr() {
        Vector<DiskMgr> retval = new Vector<DiskMgr>();
        retval.addAll(diskList.values());
        Collections.sort(retval, new DiskMgrComparator());
        return retval;
    }

    public static DiskMgr getDiskMgrOrNull(String name) throws Exception {
        if (diskList == null) {
            getDiskList();
        }
        DiskMgr retval = diskList.get(name.toLowerCase());
        return retval;
    }

    public static DiskMgr getDiskMgr(String name) throws Exception {
        DiskMgr retval = getDiskMgrOrNull(name);
        if (retval == null) {
            throw new JSONException("can not find a disk manager with the name ({0})", name);
        }
        return retval;
    }

    /**
     * Find the DiskMgr that corresponds to the real file path provided.
     * Note that there can be several matches since some DiskMgrs are
     * equal to the beginning of others.  So the longest match must be found.
     */
    public static DiskMgr findDiskMgrFromPath(File path) {
        String store = path.toString().toLowerCase();
        int longestFound = 0;
        DiskMgr foundDm = null;
        for (DiskMgr dm : getAllDiskMgr()) {
            String dmPath = dm.mainFolder.toString().toLowerCase();
            if (store.startsWith(dmPath)) {
                if (dmPath.length() > longestFound) {
                    longestFound = dmPath.length();
                    foundDm = dm;
                }
            }
        }
        return foundDm;
    }



    static public String fixSlashes(String sin) {
        int pos = sin.indexOf('\\');
        while (pos >= 0) {
            sin = sin.replace('\\', '/');
            pos = sin.indexOf('\\');
        }
        return sin;
    }

    // this test routine to help support conversion to an ALL forward slash
    // design
    static public void assertNoBackSlash(String testPath) throws Exception {
        if (testPath.indexOf('\\') >= 0) {
            throw new JSONException("Path contains a backslash: {0} ", testPath);
        }
    }

    public File getFilePath(String localPath) {
        return new File(mainFolder, localPath);
    }

    public String convertFullPathToRelativePath(String fullPath) throws Exception {
        if (!fullPath.startsWith(mainPath)) {
            throw new JSONException("Can not find relative path for ({0}) because it is not on disk at ({1})", fullPath, mainPath);
        }
        String res = fullPath.substring(mainPath.length());
        if (!res.endsWith("/")) {
            res = res + "/";
        }
        return res;
    }

    public String getRelativePath(File path) throws Exception {
        String fullPath = fixSlashes(path.getAbsolutePath());
        return convertFullPathToRelativePath(fullPath);
    }

    public String getOldRelativePathWithoutSlash(File path) throws Exception {
        String fullPath = getRelativePath(path);
        //the only difference is that there used to NOT be a slash
        //on the end, so removed it
        int len = fullPath.length();
        return fullPath.substring(0, len-1);
    }


    public String getLocator(String localPath) {
        return diskName + ":" + localPath;
    }


    public boolean equals(DiskMgr other) {
        return this == other;
    }


    /**
    * Cleans up the DiskMgr statics, but do not call this
    * by itself, only call     ImageInfo.garbageCollect()
    * which in turn calls this coordinated with all other
    * clean up actions.
    */
    public static void resetDiskList() throws Exception {
        if (diskList != null) {
            diskList.clear();
        }
        diskList = null;
        newsFiles = new Vector<File>();
        masterGroups.clear();
    }

    public static synchronized Hashtable<String, DiskMgr> getDiskList() throws Exception {

        //if already known, then return.
        if (diskList != null) {
            return diskList;
        }

        //not initialized, so initialize this now
        if (!rootFolder.exists()) {
            throw new JSONException("Root folder must exist: "+rootFolder.getAbsolutePath());
        }

        Hashtable<String, DiskMgr> tempTable = new Hashtable<String, DiskMgr>();
        Vector<File> newNewsList = new Vector<File>();

        File[] children = rootFolder.listFiles();
        if (children==null) {
            throw new JSONException("there is apparently no folder named: {0}", rootFolder.getAbsolutePath());
        }

        for (File cfile : children) {
            String diskName = cfile.getName();
            if (!cfile.isDirectory()) {
                continue;
            }
            if (diskName.equalsIgnoreCase("thumbs")) {
                continue; // skip the thumbnails directory
            }

            File newsFile = new File(cfile, "news.properties");
            if (newsFile.exists()) {
                newNewsList.add(newsFile);
            }

            File listFile = new File(cfile, "list.txt");
            if (!listFile.exists()) {
                continue;
            }

            tempTable.put(diskName.toLowerCase(), new DiskMgr(cfile));
        }

        diskList = tempTable;
        newsFiles = newNewsList;
        return tempTable;
    }

    public static synchronized Vector<File> getNewsFiles() throws Exception {

        if (newsFiles == null) {
            getDiskList();
        }

        return newsFiles;
    }

    private void scanDiskRecursive(File scanFile, Vector<ImageInfo> answer, Writer out)
            throws Exception {
        try {
            if (!scanFile.exists()) {
                return;
            }

            if (scanFile.isDirectory()) {
                System.out.println("DISKMGR: scanning folder: "+scanFile.getAbsolutePath());
                out.write("\n<li>");
                out.write(scanFile.toString());
                out.flush();
                int count=0;
                for (File child : scanFile.listFiles()) {
                    if (++count % 100 == 99) {
                        out.write("\n<li>" + count + ": " + child.getName());
                        out.flush();
                    }
                    scanDiskRecursive(child, answer, out);
                }
                return;
            }

            String fileNamelc = scanFile.getName().toLowerCase();

            if (scanFile.isFile() && (fileNamelc.endsWith(".jpg"))) {
                ImageInfo ii = ImageInfo.genFromFile(scanFile);
                answer.addElement(ii);
            }
        }
        catch (Exception e) {
            throw new JSONException("Unable to scan disk ({0} @ {1})", e, diskName, scanFile.toString());
        }
    }

    private void scanDiskOneFolder(File scanFile, Vector<ImageInfo> answer) throws Exception {
        System.out.println("scanDiskOneFolder: "+scanFile);
        try {
            if (!scanFile.exists()) {
                return;
            }
            if (!scanFile.isDirectory()) {
                throw new JSONException("scanDiskOneFolder must be passed a folder (directory)");
            }
            for (File child : scanFile.listFiles()) {
                String childName = child.getName();
                if (child.isFile() && (childName.endsWith(".jpg") || childName.endsWith(".JPG"))) {
                    ImageInfo ii = ImageInfo.genFromFile(child);
                    answer.addElement(ii);
                }
            }
        }
        catch (Exception e) {
            throw new JSONException("Unable to scan disk ({0} @ {1})", e, diskName, scanFile);
        }
    }



    public synchronized void loadDiskImages(Writer out) throws Exception {
        try {

            // now scan the disk for files
            // String auxDirName = mainFolder + "extra";
            Vector<ImageInfo> imagesForDisk = new Vector<ImageInfo>();
            scanDiskRecursive(mainFolder, imagesForDisk, out);

            out.write("\n<li><hr/></li>\n<li>Directories have been scanned, now accepting</li>");

            MongoDB mongo = new MongoDB();
            mongo.clearAllFromDisk(diskName);
            mongo.close();

            isChanged = false;
            writeSummary();
            storeDiskInMongo(imagesForDisk);
        }
        catch (Exception e) {
            throw new JSONException("Unable to load the disk '{0}'", e, diskName);
        }
    }


    
    public static void refreshDiskFolder(File folderPath) throws Exception {
        Set<File> fileList = new HashSet<File>();
        fileList.add(folderPath);
        refreshFolders(fileList);
    }
    
    public static void refreshFolders(Set<File> fileList) throws Exception {
        MongoDB mongo = new MongoDB();
        for (File folderPath : fileList) {
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(folderPath);
            String relPath = dm.getRelativePath(folderPath);
            mongo.clearAllFromDiskPath(dm.diskName, relPath);
            Vector<ImageInfo> imagesForDisk = new Vector<ImageInfo>();
            dm.scanDiskOneFolder(folderPath, imagesForDisk);
            dm.storeDiskInMongo(imagesForDisk);
        }
        mongo.close();
    }



    public synchronized void writeSummary() throws Exception {
        try {
            /*
            HashCounterIgnoreCase groupCount = new HashCounterIgnoreCase();
            HashCounterIgnoreCase posPatCount = new HashCounterIgnoreCase();
            int extraCount2 = 0;
            long extraSize2 = 0;
            
            for (ImageInfo i2 : ImageInfo.getImagesByName()) {
                if (this != i2.diskMgr) {
                    continue; // skip image from other disks
                }

                StringBuffer posPatVal = new StringBuffer(100);
                String relPath = i2.getRelativePath();
                posPatVal.append(relPath);
                if (!relPath.endsWith("/")) {
                    System.out.println("Image had a relative path that did not have a slash on the end: "
                                    + relPath + ":" + i2.fileName);
                    posPatVal.append("/");
                }
                posPatVal.append(i2.pp.getPattern());
                posPatCount.increment(posPatVal.toString());

                for (String aGroup : i2.getTagNames()) {
                    groupCount.increment(aGroup);
                }

                int fs = i2.fileSize;
                extraSize2 += fs;
                extraCount2++;
            }

            extraCount = extraCount2;
            extraSize = extraSize2;

            // write out the statistics to disk
            File newFile = new File(mainFolder,"stats.txt");
            FileWriter fr = new FileWriter(newFile);
            fr.write("0");
            fr.write("\n0");
            fr.write("\n" + extraCount);
            fr.write("\n" + extraSize);
            fr.write("\n");
            fr.flush();
            fr.close();

            groupCount.writeToFile(new File(mainFolder,"groups.txt"));
            allTagCnts = groupCount;
            posPatCount.writeToFile(new File(mainFolder,"posPat.txt"));
            isChanged = false;
            */
        }
        catch (Exception e) {
            throw new JSONException("Unable to write summary for disk '{0}", e, diskName);
        }
    }


    /**
     * Suppress the file. Either delete the file if it is in the extra
     * directory, or else make an entry in the supp.txt file in order to hide it
     * from future manipulations.
     */
    public void suppressFile(File theFile) throws Exception {
        assertOnDisk(theFile);
        try {
            if (!theFile.exists()) {
                return; // the file is already gone
            }
            if (!theFile.isFile()) {
                throw new JSONException("something wrong, it is not a file at {0}",
                       theFile.getAbsolutePath());
            }
            if (!theFile.delete()) {
                throw new JSONException("OS failed to delete local file {0}",
                       theFile.getAbsolutePath());
            }
            System.out.println("DELETED FILE: "+theFile);
            if (theFile.exists()) {
                throw new JSONException("Unable to delete Local file {0}",
                        theFile.getAbsolutePath());
            }
        }
        catch (Exception e) {
            throw new JSONException("Unable to suppress file disk={0}, fullpath={1}", e, diskName, theFile);
        }
        isChanged = true;
    }

    public void assertOnDisk(File fromPath) throws Exception {
        String fromPathStr = fromPath.getAbsolutePath();
        String containStr  = mainFolder.getAbsolutePath();
        if (!fromPathStr.startsWith(containStr)) {
            throw new JSONException("Initial path MUST start with '{0}', instead received: {1}", 
                    containStr, fromPathStr);
        }
    }




    public static void copyFile(File source, File dest) throws Exception {
        if (!source.exists()) {
            throw new JSONException("The source file does not exist: {0}.",source);
        }
        if (dest.exists()) {
            dest.delete();
        }
        else {
            File destParent = dest.getParentFile();
            destParent.mkdirs();
        }
        FileInputStream fis = new FileInputStream(source);
        FileOutputStream fos = new FileOutputStream(dest);
        byte[] buff = new byte[8192];
        int amt = fis.read(buff);
        while (amt > 0) {
            fos.write(buff, 0, amt);
            amt = fis.read(buff);
        }
        fis.close();
        fos.close();
    }

    /**
     * Move a file from a particular (real) location to a virtual location on
     * this disk.
     *
     * If the disk already contains that file a new file name is generated with
     * a new or changed disambiguation token. The actual file name used is
     * returned.
     */
    public String moveFileToDisk(DiskMgr fromDisk, String fromPath, String fileName, File toPath)
            throws Exception {
        try {
            assertOnDisk(toPath);
            File fPath = new File(fromPath);

            // suppress moves to the same location
            if (diskName.equalsIgnoreCase(fromDisk.diskName)
                    && toPath.equals(fPath)) {
                return fileName; // nothing to do
            }

            String newToName = findSuitableName(toPath, fileName);

            File toFile = new File(toPath, newToName);
            File fromFile = new File(fPath, fileName);
            if (toFile.exists()) {
                throw new JSONException(
                    "New logic of findSuitableName should assure that the destination file does not exist:{0}",
                            toFile);
            }

            toPath.mkdirs();
            FileInputStream fis = new FileInputStream(fromFile);
            FileOutputStream fos = new FileOutputStream(toFile);
            byte[] buff = new byte[8192];
            int amt = fis.read(buff);
            while (amt > 0) {
                fos.write(buff, 0, amt);
                amt = fis.read(buff);
            }
            fis.close();
            fos.close();

            fromDisk.suppressFile(fromFile);
            isChanged = true;

            if (!toFile.exists()) {
                throw new JSONException("New file did not get created during copy?!? {0}",toFile);
            }
            if (fromFile.exists()) {
                throw new JSONException("Old file still exists, after move: {0}", fromFile);
            }

            return newToName;
        }
        catch (Exception e) {
            throw new JSONException("Unable to moveFileTo fromDisk={0}, fromPath={1}, fileName={2}, toPath={3}",
                    e, fromDisk.diskName, fromPath, fileName, toPath);
        }
    }

    /**
     * generate a token for creating deconflicting names. is three letters,
     * always z & y 0 == z 2==yz 4==yzz 6==yyz 8==yzzz 1 == y 3==yy 5==yzy
     * 7==yyy 9==yzzy
     */
    private String deconflictingToken(int val) {
        StringBuffer res = new StringBuffer(8);
        addDigit(res, val);
        return res.toString();
    }

    private void addDigit(StringBuffer res, int val) {
        int bit = val % 2;
        int higher = val / 2;
        if (higher > 0) {
            addDigit(res, higher);
        }
        if (bit > 0) {
            res.append("y");
        }
        else {
            res.append("z");
        }
    }

    private boolean isDeconflictToken(String possible) {
        if (possible.length() == 0) {
            return false;
        }

        for (int i = 0; i < possible.length(); i++) {
            char ch = possible.charAt(i);
            if (ch < 'y' || ch > 'z') {
                return false;
            }
        }

        return true;
    }

    public String findSuitableName(File folderPath, String newName) throws Exception {
        // first find and pull the suffix off
        int lastDotPos = newName.lastIndexOf(".");
        if (lastDotPos < 0) {
            throw new JSONException(
                    "Unable to find a suitable name because the desired destinationg name does not have any suffix: {0}",
                    newName);
        }
        String suffix = newName.substring(lastDotPos);
        String front = newName.substring(0, lastDotPos);

        // now look to see if there are any deconflicting tokens. walk through
        // looking at every token type thing, and if it looks like DT remove it.
        int startPos = front.indexOf(".");
        while (startPos >= 0 && startPos < front.length() - 1) {
            int nextDot = front.indexOf(".", startPos + 1);
            if (nextDot == startPos + 1) {
                // remove the second of two dots in a row
                front = front.substring(0, startPos) + front.substring(nextDot);
            }
            else if (nextDot > startPos + 1) {
                if (isDeconflictToken(front.substring(startPos + 1, nextDot))) {
                    front = front.substring(0, startPos) + front.substring(nextDot);
                }
            }
            else if (nextDot < 0) {
                if (isDeconflictToken(front.substring(startPos + 1))) {
                    front = front.substring(0, startPos);
                }
            }
            startPos = nextDot;
        }

        // try the name without any deconflicting tokens
        File toFile = new File(folderPath, front + suffix);
        if (!toFile.exists()) {
            return front + suffix;
        }

        // try the name iterating through deconflicting tokens
        int count = 0;
        while (true) {
            String cToken = deconflictingToken(count);
            String testName = front + "." + cToken + suffix;
            toFile = new File(folderPath, testName);
            if (!toFile.exists()) {
                return testName;
            }
            count++;
        }
    }

    /**
     * throws an exception if there is a conflict on changing a file to a new
     * name
     */
    public void assertRenamePossible(File path, String oldName, String newName) throws Exception {
        // rename to the current name is silently ignored
        if (oldName.equals(newName)) {
            return;
        }

        File fromFile = new File(path, oldName);
        if (!fromFile.exists()) {
            throw new JSONException("Can not rename a file that does not exist: {0}", fromFile.getPath());
        }

        File toFile = new File(path, newName);
        if (toFile.exists()) {

            // handle the special case if the file name differs only by case,
            // then the existing
            // file is precisely the same file as the one being renamed.

            if (!oldName.equalsIgnoreCase(newName)) {
                throw new JSONException(
                        "Can not rename a file because a file already exists with that name: {0}",
                        toFile.getPath());
            }
        }
    }

    public void renameDiskFile(File path, String oldName, String newName) throws Exception {
        // rename to the current name is silently ignored
        if (oldName.equals(newName)) {
            return;
        }

        assertRenamePossible(path, oldName, newName);

        File fromFile = new File(path, oldName);
        File toFile = new File(path, newName);
        fromFile.renameTo(toFile);
        isChanged = true;
    }

    public boolean fileExists(File path, String name) throws Exception {
        File aFile = new File(path, name);
        return aFile.exists();
    }

    public int getPatternCount(String pattern) {
        return PosPat.countAllPatternOnDisk(this, pattern);
    }

    public int getTagCount(String tag) {
        return allTagCnts.getCount(tag);
    }

    public List<String> getTagList() {
        return allTagCnts.sortedKeys();
    }

    
    public JSONObject getJson() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("diskName",  diskName);
        return jo;
    }

    
    public void storeDiskInMongo(Vector<ImageInfo> imagesForDisk) throws Exception {
        MongoDB mongo = new MongoDB();
        
        List<String> allPP = new Vector<String>();
        //first, find all the pospat symbols
        for (ImageInfo ii : imagesForDisk) {
            String symbol = ii.getPatternSymbol();
            if (!allPP.contains(symbol)) {
                allPP.add(symbol);
            }
        }
        
        //now walk through the images by pospat symbol
        for (String ss : allPP) {
            List<ImageInfo> imagesForPP = new ArrayList<ImageInfo>();
            for (ImageInfo ii : imagesForDisk) {
                String symbol = ii.getPatternSymbol();
                if (ss.equals(symbol)) {
                    imagesForPP.add(ii);
                }
            }
            if (imagesForPP.size()>0) {
                System.out.println("DISKMGR: stored "+ss+" in DB");
                mongo.createPosPatRecord(ss, imagesForPP);
            }
        }

        mongo.close();
    }
    public void updateSymbolsInMongo(List<String> symbolList) throws Exception {
        MongoDB mongo = new MongoDB();
        
        for (String symbol : symbolList) {
            PosPat pp = PosPat.getPosPatFromSymbol(symbol);
            if (pp!=null) {
                mongo.updatePosPat(pp);
            }
        }
        mongo.close();
    }
    

    /***************** HELPER CLASSES *********************/

    static class DiskMgrComparator implements Comparator<DiskMgr> {
        public DiskMgrComparator() {
        }

        public int compare(DiskMgr o1, DiskMgr o2) {
            return o1.diskName.compareToIgnoreCase(o2.diskName);
        }
    }

    static class StringComparator implements Comparator<String> {
        public StringComparator() {
        }

        public int compare(String o1, String o2) {
            return o1.compareToIgnoreCase(o2);
        }
    }


}
