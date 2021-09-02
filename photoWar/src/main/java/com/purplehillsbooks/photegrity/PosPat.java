package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

/**
 * Images are grouped into 'pospat' group, that is a particular pattern in a
 * particular location on the disk. This object keeps statistics about that
 * grouping, and also holds a static index.
 *
 */
public class PosPat {

    private DiskMgr diskMgr;
    private String localPath;
    private String pattern;
    private List<String> pathTags = new ArrayList<String>();
    private int imageCount;
    private HashCounterIgnoreCase tags;
    private static Hashtable<String,PosPat> ppIndex = new Hashtable<String,PosPat>();
    private static Hashtable<String,String> compressor = new Hashtable<String,String>();


    public PosPat(DiskMgr _dm, String _localPath, String _pattern) {
        if (!_localPath.endsWith("/")) {
            //should we complain?  Or just fix it up?
            //_localPath = _localPath + "/";
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: "+_localPath);
        }
        localPath = compressor.get(_localPath);
        if (localPath==null) {
            compressor.put(_localPath, _localPath);
            localPath = _localPath;
        }
        diskMgr = _dm;
        pattern = compressor.get(_pattern);
        if (pattern==null) {
            compressor.put(_pattern, _pattern);
            pattern = _pattern;
        }
        tags = new HashCounterIgnoreCase();
        for (String possTag : parsePathTags(_localPath)) {
            pathTags.add(possTag);
        }
        for (String possTag : parsePathTags(diskMgr.diskNameLowerCase)) {
            pathTags.add(possTag);
        }
    }

    public DiskMgr getDiskMgr() {
        return diskMgr;
    }
    public String getLocalPath() {
        return localPath;
    }
    public String getPattern() {
        return pattern;
    }

    public File getFolderPath() {
        return diskMgr.getFilePath(localPath);
    }
    public File getFilePath(String fileName) {
        return new File(getFolderPath(), fileName);
    }
    public Vector<File> getMatchingFiles() {
        File folder = getFolderPath();
        Vector<File> children = new Vector<File>();
        for (File child : folder.listFiles()) {
            if (child.getName().startsWith(pattern)) {
                children.add(child);
            }
        }
        return children;
    }
    /**
    * This is a key identifying string of the form:
    *  <diskName>:<localPath><pattern>
    */
    public String getSymbol() {
        return diskMgr.getLocator(localPath) + pattern;
    }
    public String getLocator() {
        return diskMgr.getLocator(localPath);
    }
    public static PosPat getPosPatFromSymbol(String symbol) throws Exception {
        int colonPos = symbol.indexOf(':');
        if (colonPos<=0) {
            throw new JSONException("improperly formed symbol does not have disk name before colon: ({0})",symbol);
        }
        DiskMgr dm = DiskMgr.getDiskMgr(symbol.substring(0, colonPos));
        String rest = symbol.substring(colonPos+1);
        int slashPos = rest.lastIndexOf('/')+1;
        if (slashPos<=0) {
            throw new JSONException("improperly formed symbol does not have slash before pattern: ({0})",symbol);
        }
        String localPath = rest.substring(0, slashPos);
        String pattern = rest.substring(slashPos);
        
        return findOrCreate(dm, localPath, pattern);
    }
    public static PosPat getPosPatFromSymbolOrNull(String symbol) throws Exception {
        int colonPos = symbol.indexOf(':');
        if (colonPos<=0) {
            return null;
        }
        DiskMgr dm = DiskMgr.getDiskMgrOrNull(symbol.substring(0, colonPos));
        if (dm==null) {
            return null;
        }
        String rest = symbol.substring(colonPos+1);
        int slashPos = rest.lastIndexOf('/')+1;
        if (slashPos<=0) {
            return null;
        }
        String localPath = rest.substring(0, slashPos);
        String pattern = rest.substring(slashPos);
        
        return findOrCreate(dm, localPath, pattern);
    }

    
    public List<String> getTags() {
        return tags.sortedKeys();
    }
    public List<String> getPathTags() {
        return pathTags;
    }
    public boolean hasTag(String tag) {
        return (tags.getCount(tag)>0 || pathTags.contains(tag));
    }
    public int getImageCount() {
        return imageCount;
    }

    public void addTag(String newTag) throws Exception {
        tags.increment(newTag);
    }
    public void removeTag(String oldTag) throws Exception {
        tags.decrement(oldTag);
    }
    public int countForTag(String tag) throws Exception {
        return tags.getCount(tag);
    }

    public void setImageCount(int val) {
        imageCount = val;
    }

    @Deprecated
    public static synchronized PosPat findOrCreate(DiskMgr _dm, String _localPath, String _pattern) throws Exception {
        return findOrCreate(_dm.diskName+":"+_localPath+_pattern);
    }
    
    public static synchronized PosPat findOrCreate(String symbol) throws Exception {
        PosPat found = ppIndex.get(symbol);
        if (found!=null) {
            return found;
        }
        int colonPos = symbol.indexOf(":");
        if (colonPos<=0) {
            throw new Exception("Symbol for PosPat is missing a colon character");
        }
        String disk = symbol.substring(0, colonPos);
        DiskMgr diskMgr = DiskMgr.getDiskMgr(disk);
        int lastSlash = symbol.lastIndexOf("/");
        if (lastSlash<=colonPos) {
            throw new Exception("Symbol for PosPat is missing any slash character");
        }
        String path = symbol.substring(colonPos+1, lastSlash+1);
        String pattern = symbol.substring(lastSlash+1);
        found = new PosPat(diskMgr, path, pattern);
        ppIndex.put(symbol, found);
        return found;
    }


    /**
     * clear everything out for garbage collection
     */
    public static void clearAllCache() {
        ppIndex.clear();
    }

    /**
     * Find all PosPat objects with a given pattern
     */
    public static List<PosPat> findAllPattern(String _pattern) {
        throw new RuntimeException("not implemented");
        /*
        int pos = findFirstEntryWithPattern(ppIndex, _pattern);
        Vector<PosPat> res = new Vector<PosPat>();
        while (true) {
            if (pos>=ppIndex.size()) {
                return res;
            }
            PosPat pp = ppIndex.get(pos);
            int comp = _pattern.compareToIgnoreCase(pp.pattern);
            if (comp<0) {
                //no more entries with this pattern, nothing found
                return res;
            }
            if (_pattern.equalsIgnoreCase(pp.pattern) && pp.imageCount>0) {
                res.add(pp);
            }
            pos++;
        }
        */
    }

    /**
     * Find all PosPat objects with a given pattern
     */
    public static int countAllPatternOnDisk(DiskMgr dm, String _pattern) {
        throw new RuntimeException("not implemented");
        /*
        int pos = findFirstEntryWithPattern(ppIndex, _pattern);
        int count = 0;
        while (true) {
            if (pos>=ppIndex.size()) {
                return count;
            }
            PosPat pp = ppIndex.get(pos);
            int comp = _pattern.compareToIgnoreCase(pp.pattern);
            if (comp<0) {
                //no more entries with this pattern, nothing found
                return count;
            }
            if (_pattern.equalsIgnoreCase(pp.pattern) && dm.equals(pp.getDiskMgr())) {
                count += pp.getImageCount();
            }
            pos++;
        }
        */
    }



    public static synchronized List<PosPat> getAllForDisk(DiskMgr dm) throws Exception {
        List<PosPat> newIndex = new ArrayList<PosPat>();
        for (PosPat pp : ppIndex.values()) {
            if (pp.diskMgr.equals(dm)) {
                newIndex.add(pp);
            }
        }
        return newIndex;
    }

    public static List<PosPat> filterByTag(List<PosPat> input, String tag) {
        Vector<PosPat> res = new Vector<PosPat>();
        for (PosPat pp : input) {
            if (pp.hasTag(tag)  && pp.imageCount>0) {
                res.add(pp);
            }
        }
        return res;
    }


    public static void sortByPattern(List<PosPat> list) {
        Collections.sort(list, new PosPatComparator());
    }
    public static void sortByPath(List<PosPat> list) {
        Collections.sort(list, new PosPatPathOrderComparator());
    }


    /**
     * This is a generally useful method that will take a string that has
     * a string of tokens separate by either slask, backslash, or dot (period)
     * and return them as a vector of string values (in the same order).
     * it is public static, so just pass in the string and get vector back,
     * no side effects.
     */
    public static Vector<String> parsePathTags(String path) {
        String pathlc = path.toLowerCase();
        int startPos = 0;
        int pos = 0;
        Vector<String> res = new Vector<String>();
        while (pos<pathlc.length()) {
            char ch = pathlc.charAt(pos);
            if (ch==':' || ch=='.' || ch=='/'  || ch=='\\') {
                if (pos > startPos) {
                    res.add(pathlc.substring(startPos, pos));
                }
                startPos = pos+1;
            }
            pos++;
        }
        if (pathlc.length() > startPos) {
            res.add(pathlc.substring(startPos));
        }
        return res;
    }


    /**
     * Pass in a File object pointing to either a folder
     * or a file in the file system.  Will return a properly
     * formatted newly created PosPat object with the right
     * disk manager, local path, and pattern if applicable.
     * If you pass in a folder, then the pattern will be null string
     * If you pass in a file, the pattern will be correct for that file.
     */
    public static PosPat getPosPatFromPath(File input) throws Exception {
        try {
            if (!input.exists()) {
                throw new JSONException("Input file must exist");
            }
            File folder = input;
            String pattern = "";
            if (!input.isDirectory()) {
                FracturedFileName ffn = FracturedFileName.parseFile(input.getName());
                pattern = ffn.prePart;
                folder = input.getParentFile();
            }
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(folder);
            if (dm==null) {
                throw new JSONException("Unable to locate a DiskManager for the path {0}", folder);
            }
            String localPath = dm.getOldRelativePathWithoutSlash(folder);
            PosPat res = findOrCreate(dm, localPath, pattern);
            return res;
        }
        catch (Exception e) {
            throw new JSONException("Unable to create a PosPath object for {0}",input);
        }
    }

    /**************** HELPER CLASSES *********************/

    private static class PosPatComparator implements Comparator<PosPat> {
        public PosPatComparator() {
        }

        public int compare(PosPat o1, PosPat o2) {
            int res = o1.pattern.compareToIgnoreCase(o2.pattern);
            if (res != 0) {
                return res;
            }
            res = o1.localPath.compareToIgnoreCase(o2.localPath);
            if (res != 0) {
                return res;
            }
            res = o1.diskMgr.diskName.compareToIgnoreCase(o2.diskMgr.diskName);
            return res;
        }
    }


    private static class PosPatPathOrderComparator implements Comparator<PosPat> {
        public PosPatPathOrderComparator() {
        }

        public int compare(PosPat o1, PosPat o2) {
            int res = o1.diskMgr.diskName.compareToIgnoreCase(o2.diskMgr.diskName);
            if (res != 0) {
                return res;
            }
            res = o1.localPath.compareToIgnoreCase(o2.localPath);
            if (res != 0) {
                return res;
            }
            res = o1.pattern.compareToIgnoreCase(o2.pattern);
            return res;
        }
    }
    
    public String translateFileName(String sourceFile) {
        FracturedFileName ffn = FracturedFileName.parseFile(sourceFile);
        return pattern+ffn.numPart+ffn.tailPart;
    }
    public FracturedFileName translateFracFileName(String sourceFile) {
        FracturedFileName ffn = FracturedFileName.parseFile(sourceFile);
        ffn.prePart = pattern;
        return ffn;
    }
    
    /**
     * All the files at this position, and matching the pattern
     * will be moved and renamed to the PosPat passed in.
     * If a file already exists at the destinatin, then the 
     * source file is simply deleted, old dest remains.
     */
    public void moveAllFiles(PosPat dest) throws Exception {
        File sourceFolder = getFolderPath();
        String sourcePatt = getPattern();
        File destFolder = dest.getFolderPath();
        destFolder.mkdirs();
        for (File child : sourceFolder.listFiles()) {
            String fileName = child.getName();
            FracturedFileName parts = FracturedFileName.parseFile(fileName);
            if (sourcePatt.equalsIgnoreCase(parts.prePart)) {
                FracturedFileName destFFN = parts.copy();
                destFFN.prePart = dest.getPattern();
                String destName = destFFN.existsAs(destFolder);
                if (destName==null) {
                    File destFile = new File(destFolder,destFFN.getRegularName());
                    moveFileContents(child, destFile);
                }
                child.delete();
            }
        }
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

    public List<ImageInfo> scanDiskForImages() throws Exception {
        List<ImageInfo> imageList =  new ArrayList<ImageInfo>();
        File parentFolder = diskMgr.getFilePath(localPath);
        for (File child : parentFolder.listFiles()) {
            if (child.isDirectory()) {
                continue;
            }
            ImageInfo ii = ImageInfo.genFromFile(child);
            if (pattern.equals(ii.getPattern())) {
                imageList.add(ii);
            }
        }
        return imageList;
    }
    
    public List<ImageInfo> getImagesFromDB() throws Exception {
        String symbol = getSymbol();
        MongoDB mongo = new MongoDB();
        String query = "x("+symbol+")";
        JSONArray listOfOne = mongo.querySets(query);
        if (listOfOne.length()<1) {
            throw new Exception("Could not find any records for this pospat: "+symbol);
        }
        JSONObject pp = listOfOne.getJSONObject(0);
        JSONArray images = pp.getJSONArray("images");
        
        List<ImageInfo> imageList =  new ArrayList<ImageInfo>();
        for (JSONObject image : images.getJSONObjectList()) {
            imageList.add(ImageInfo.genFromJSON(image));
        }
        return imageList;
    }
    
    private static Random rand = new Random();
    public List<ImageInfo> getSomeRandomImages(int num) throws Exception {
        List<ImageInfo> completeList = getImagesFromDB();
        if (completeList.size()==0) {
            throw new Exception("There are no images for pospat: "+getSymbol());
        }
        List<ImageInfo> imageList =  new ArrayList<ImageInfo>();
        for (ImageInfo ii : completeList) {
            if (ii.value == -300) {
                imageList.add(ii);
            }
        }
        while (imageList.size()<num) {
            int pick = rand.nextInt(completeList.size());
            imageList.add(completeList.get(pick));
        }
        return imageList;
    }
    
    public JSONObject getFullMongoDoc() throws Exception {
        List<ImageInfo> imageList =  scanDiskForImages();
        return getFullMongoDoc(imageList);
    }
    
    public JSONObject getFullMongoDoc(List<ImageInfo> imageList) throws Exception {
        
        String symbol = getSymbol();
        
        JSONObject jo = new JSONObject();
        jo.put("disk", diskMgr.diskName);
        
        jo.put("path", localPath);
        jo.put("pattern", pattern);
        jo.put("symbol", getSymbol());
        JSONArray tags = new JSONArray();
        for (String tag : pathTags) {
            tags.put(tag);
        }
        jo.put("tags", tags);
        jo.put("imageCount", imageList.size());
        long totalSize = 0;
        for (ImageInfo ii : imageList) {
            totalSize = totalSize + ii.getFileSize();
        }
        jo.put("totalSize", totalSize);
        
        JSONArray images = new JSONArray();
        boolean hasSample = false;
        int minVal = 9999;
        int maxVal = 0;
        int count = 0;
        for (ImageInfo ii : imageList) {
            if (!symbol.equals(ii.pp.getSymbol())) {
                //ignore any image passed that is not actually in this PosPat set
                continue;
            }
            if (ii.value==-300) {
                hasSample = true;
            }
            else if (ii.value>0) {
                if (ii.value<minVal) {
                    minVal = ii.value;
                }
                if (ii.value>maxVal) {
                    maxVal = ii.value;
                }
            }
            count++;
            images.put(ii.getJSON());
        }
        if (images.length()==0) {
            throw new Exception("Attempt to register a ImageSet without any actual images in it:  "+symbol);
        }
        jo.put("images",  images);
        jo.put("hasSample",  hasSample);
        jo.put("max",  maxVal);
        jo.put("min",  minVal);
        jo.put("compactness", ((float)maxVal - (float)minVal)/count);

        return jo;
   }

}
