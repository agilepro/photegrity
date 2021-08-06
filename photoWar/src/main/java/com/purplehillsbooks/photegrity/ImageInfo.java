package com.purplehillsbooks.photegrity;

import java.io.File;
import java.net.URLEncoder;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class ImageInfo
{
    public PosPat  pp;  //holds disk and rel path and pattern info

    public DiskMgr diskMgr;  // this image is in this collection

    public String  fileName; // the original and actual filename
    public int     value;    // numeric value of this file name
    public String  tail;     // rest of the file name after the number

    public int    fileSize;
    private Vector<String> tagNames;
    public int    randomValue;

    public boolean isIndex = false;
    public boolean isTrashed = false;

    public static boolean unsorted = true;
    public static Hashtable<String, String> pathCompressor = new  Hashtable<String, String>();

    private static ImageInfo nullImage = null;

    public static int MEMORY_SIZE = 20;
    public static MarkedVector[] memory = {new MarkedVector(), new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector(), new MarkedVector(),
                                           new MarkedVector(), new MarkedVector()};
    public static Random randGen = new Random();

    public ImageInfo(File filePath, DiskMgr disk)
        throws Exception
    {
        try {
            diskMgr = disk;
            tagNames = new Vector<String>();
            randomValue = randGen.nextInt(1000000000);

            fileName = filePath.getName();
            fileSize = (int) filePath.length();

            File parentFolder = filePath.getParentFile();
            String relativePath = diskMgr.getRelativePath(parentFolder);

            initializeInternals(relativePath);
        }
        catch (Exception e) {
            throw new JSONException("Unable to create image info for {0}",e,filePath);
        }
    }
    
    /**
    * Used only for Null Images
    */
    private ImageInfo() {
        diskMgr = null;
        fileName = "";
        value = 0;
        tail = "";
        fileSize = 0;
        tagNames = new Vector<String>();
        randomValue = 0;
        isIndex = false;
    }

    public static ImageInfo getNullImage()
    {
        if (nullImage == null) {
            nullImage = new ImageInfo();
        }
        return nullImage;
    }

    public boolean isNullImage() {
        return (diskMgr == null);
    }


    public PosPat getPosPat() {
        //initially implement to search and find this
        return pp;
    }

    public String getRelativePath() {
        return pp.getLocalPath();
    }

    /**
    * @deprecated use getFilePath instead
    */
    public String getFullPath() throws Exception {
        return DiskMgr.fixSlashes(diskMgr.getFilePath(getRelativePath()).toString()+"/");
    }

    public File getFolderPath() throws Exception {
        return pp.getFolderPath();
    }
    public File getFilePath() throws Exception {
        return pp.getFilePath(fileName);
    }

    public String getPattern() {
        return pp.getPattern();
    }
    public String getPatternSymbol() {
        return pp.getSymbol();
    }


    /**
    * returns the file size as a string
    */
    public String fileSizeStr() {
        return Integer.toString(fileSize);
    }



    /********************************************************/


    public static void sortImages(List<ImageInfo> images, String order)
        throws Exception
    {
        Comparator<ImageInfo> sc;
        if (order.equals("path")) {
            sc = new ImagesByPathComparator();
        }
        else if (order.equals("size")) {
            sc = new ImagesBySizeComparator();
        }
        else if (order.equals("num")) {
            sc = new ImagesByNumComparator();
        }
        else if (order.equals("rand")) {
            sc = new ImagesRandomizer();
        }
        else if (order.equals("name")) {
            sc = new ImagesByNameComparator();
        }
        else if (order.equals("none")) {
            return;
        }
        else {
            throw new JSONException("I don't understand how to sort by '{0}'.  Please request a sort by path, size, num, rand, name, or none.", order);
        }
        Collections.sort(images, sc);
    }


    /********************************************************/


    public void unsplit() throws Exception
    {
        if (tail == null) {
            return;
        }
        tagNames.clear();
        tail = null;
    }

    private void initializeInternals(String relPath) throws Exception
    {
        if (tail != null) {
            throw new JSONException("Hmmm, initializeInternals method is being called twice?");
        }
        try {
            if (diskMgr == null) {
                throw new JSONException("diskMgr member is null, on image {0}, relPath={1}",fileName,relPath);
            }
            if (relPath == null) {
                throw new JSONException("Problem with initialization, relPath is null");
            }

            FracturedFileName ffn = FracturedFileName.parseFile(fileName);
            isIndex = ffn.isNegative();
            
            //this converts a file name from this form
            //     !myIndex001.jpg
            //to this form
            //     myIndex!001.jpg
            //if needed.  not sure this is really needed.
            int exclaimPos = ffn.prePart.indexOf('!');  //remove the bang if there is one
            if (exclaimPos>=0) {
                System.out.println("CONVERTING file name bang: "+fileName);
                isIndex = true;
                ffn.prePart = ffn.prePart.substring(0,exclaimPos) + ffn.prePart.substring(exclaimPos+1);
                if (!ffn.numPart.startsWith("!")) {
                    ffn.numPart = "!"+ffn.numPart;
                }
            }
            
            pp = PosPat.findOrCreate(diskMgr, relPath, ffn.prePart);
            value = ffn.getSequenceNumber();
            tail = ffn.tailPart;

            determineTags();
        }
        catch (Exception e) {
            throw new JSONException("Unable to split into patterns ({0})({1})",e,relPath,fileName);
        }
    }

    public void determineTags() throws Exception {
        HashCounterIgnoreCase cache = new HashCounterIgnoreCase();
        cache.increment(diskMgr.diskNameLowerCase);  //might include dots in this case

        //get tag values from the tail
        //skip any characters after the number, but before the dot
        int startPos = tail.indexOf('.');
        if (startPos>=0 && startPos < tail.length()-4) {
            parsePathTags(cache, tail.substring(startPos, tail.length()-4));
        }

        // now get the tags from the diskname and path
        parsePathTags(cache, diskMgr.diskNameLowerCase+"/"+getRelativePath());

        for (String scnTag : cache.sortedKeys()) {
            if (scnTag.length() == 0) {
                continue;
            }
            if (scnTag.equals("extra")) {
                continue;   //ignore this tag because everything has this
            }
            tagNames.add(scnTag);
        }
    }

    /*
    private void wipeAllConnections() {
        pp.decrementImageCount();
    }
    */


    public static void parsePathTags(HashCounterIgnoreCase cache, String path) throws Exception {
        String pathlc = path.toLowerCase();
        int startPos = 0;
        int pos = 0;
        while (pos<pathlc.length()) {
            char ch = pathlc.charAt(pos);
            if (ch==':' || ch=='.' || ch=='/'  || ch=='\\') {
                if (pos > startPos) {
                    cache.increment(pathlc.substring(startPos, pos));
                }
                startPos = pos+1;
            }
            pos++;
        }
        if (pathlc.length() > startPos) {
            cache.increment(pathlc.substring(startPos));
        }
    }



    public Vector<String> getTagNames() throws Exception {
        return tagNames;
    }


    static public String[] splitString (String start, int expected)
        throws Exception
    {
        try {
            String[] result = new String[expected];
            int pos = 0;
            for (int i=0; i<(expected-1); i++) {
                int nextpos = start.indexOf("\t", pos);
                if (nextpos < 0) {
                    throw new JSONException("Did not find the tab number {0} in ({1}) at pos={2}", i, start, pos);
                }
                result[i] = start.substring(pos, nextpos);
                pos = nextpos + 1;
            }
            result[expected-1] = start.substring(pos);
            return result;
        }
        catch (Exception e) {
            throw new JSONException("Error in splitString", e);
        }
    }


    static public void garbageCollect()
        throws Exception
    {
        // clear everything up front so that garbage collection will work
        //imagesByPath = null;
        //imagesBySize = null;
        //imagesByName = null;
        pathCompressor = new Hashtable<String, String>();
        for (int i=0; i<memory.length; i++) {
            memory[i] = new MarkedVector();
        }

        // take care of peer classes
        PosPat.clearAllCache();
        DiskMgr.resetDiskList();

        // now garbage collect
        System.gc();
    }

    static public void saveImageInfo() throws Exception
    {
        try {
            Hashtable<String, DiskMgr> ht = DiskMgr.getDiskList();
            Enumeration<String> e3 = HashCounter.sort(ht.keys());

            while (e3.hasMoreElements()) {

                String key = e3.nextElement();
                DiskMgr mgr = ht.get(key);
                if (mgr.isChanged) {
                    mgr.writeSummary();
                }
            }
        }
        catch (Exception e) {
            throw new JSONException("Failure saving image info to allNames.txt", e);
        }
    }


    /**
     * remove all images from a particular disk
     */
    public static synchronized void removeDiskImages(DiskMgr dm) {
        /*
        Vector<ImageInfo> imagesForDisk = new Vector<ImageInfo>();
        if (imagesByName != null) {
            for (ImageInfo ii : imagesByName) {
                if (ii.diskMgr != dm) {
                    imagesForDisk.add(ii);
                }
                else {
                    ii.wipeAllConnections();
                }
            }
        }
        imagesByName = imagesForDisk;
        imagesByPath = null;
        imagesBySize = null;
        imagesByNum  = null;
        */
        unsorted = true;
    }

    /**
     * remove all images from a particular disk sitting at a
     * particular relative path
     */
    private static synchronized void removeDiskPath(DiskMgr dm, String relPath) throws Exception {
        /*
        long startTime = System.currentTimeMillis();
        Vector<ImageInfo> imagesForDisk = new Vector<ImageInfo>();
        Vector<ImageInfo> wipeables = new Vector<ImageInfo>();
        if (imagesByName != null) {
            for (ImageInfo ii : imagesByName) {
                if (ii.diskMgr != dm) {
                    imagesForDisk.add(ii);
                }
                else if (!relPath.equalsIgnoreCase(ii.pp.getLocalPath())) {
                    imagesForDisk.add(ii);
                }
                else {
                    wipeables.add(ii);
                }
            }
        }
        System.out.println("removeDiskPath1 - "+(System.currentTimeMillis()-startTime)+"ms - ");
        startTime = System.currentTimeMillis();
        for (ImageInfo ii : wipeables) {
            ii.wipeAllConnections();
        }
        System.out.println("removeDiskPath1 - "+(System.currentTimeMillis()-startTime)+"ms - ");
        imagesByName = imagesForDisk;
        imagesByPath = null;
        imagesBySize = null;
        imagesByNum  = null;
        */
        unsorted = true;
    }



    public static ImageInfo findImageByPath(File filePath) throws Exception {
        DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePath);
        File parentFolder = filePath.getParentFile();
        String relPath = dm.getRelativePath(parentFolder);
        return findImage2(dm.diskName, relPath, filePath.getName());
    }
    

    /**
    *  Don't use this one, use instead the findImage that has the relPath below
    */
    public static ImageInfo findImage(String disk, String originalFullPath, String name)
        throws Exception
    {
        try {
            if (disk == null) {
                throw new JSONException("findImage was passed a null disk name");
            }
            if (originalFullPath == null) {
                throw new JSONException("findImage was passed a null originalFullPath");
            }
            DiskMgr dm = DiskMgr.getDiskMgr(disk);
            String relPath = dm.convertFullPathToRelativePath(originalFullPath);
            return findImage2(disk, relPath, name);
        }
        catch (Exception e) {
            throw new JSONException("Unable to find an image (disk={0})(originalFullPath={1})(name={2})", e, disk, originalFullPath,name);
        }
    }
    
    public static ImageInfo findImage3(JSONObject image) throws Exception {
        String symbol = image.getString("symbol");
        int pos = symbol.indexOf(":");
        String diskMgr = symbol.substring(0,pos);
        int pos2 = symbol.lastIndexOf("/");
        String relPath = symbol.substring(pos+1, pos2);
        String name = image.getString("fileName");
        return findImage2(diskMgr, relPath, name);
    }


    public static ImageInfo findImage2(String disk, String relPath, String name) throws Exception {
        if (disk == null) {
            throw new JSONException("findImage was passed a null disk name");
        }
        if (relPath == null) {
            throw new JSONException("findImage was passed a null relPath");
        }
        if (name == null) {
            throw new JSONException("findImage was passed a null file name");
        }
        if (relPath.length()>0 && !relPath.endsWith("/")) {
            throw new JSONException("relPath must either be a null string, or it must end with a slash!  instead got: {0}",relPath);
        }
        DiskMgr diskMgr = DiskMgr.getDiskMgr(disk);
        File parentPath = diskMgr.getFilePath(relPath);
        if (!parentPath.exists()) {
            throw new JSONException("Attempt to find an image on path ({0}) but path not found", parentPath.getAbsolutePath());
        }
        File fullPath = new File(parentPath, name);
        if (!parentPath.exists()) {
            throw new JSONException("Attempt to find an image on path ({0}) with name ({1}) but none found", parentPath.getAbsolutePath(), name);
        }
        return constructImageInfo(diskMgr, fullPath);
    }

    public static ImageInfo constructImageInfo(DiskMgr diskMgr, File fullPath) throws Exception {
        if (!fullPath.exists()) {
            throw new JSONException("Unable to find an image on disk ({0}), path ({1})", diskMgr.diskName, fullPath.getAbsolutePath());
        }
        return new ImageInfo(fullPath, diskMgr);
    }





    // takes this image out of the collection of images.
    private void unPlugImage()
        throws Exception
    {
        // just in case this is part of a selection
        for (int i=0; i<memory.length; i++) {
            memory[i].remove(this);
        }
    }


    public synchronized void suppressImage()
        throws Exception
    {
        //TODO: replace this with a File object
        File fPath = this.getFilePath();
        System.out.println("SUPPRESSING Image: "+fPath);
        
        try {
            PosPat.removeImage(this);

            diskMgr.suppressFile(fPath);
            deleteThumbnails();

            unPlugImage();

        } catch (Exception e) {
            throw new JSONException("Unable to suppress image {0}/{1}", e, fPath, fileName);
        }
    }

    public synchronized ImageInfo moveImageToLoc(String newLoc) throws Exception {
        DiskMgr.assertNoBackSlash(newLoc);
        int colonPos = newLoc.indexOf(":");
        String diskName = newLoc.substring(0, colonPos);
        String diskPath = newLoc.substring(colonPos+1);
        DiskMgr dm = DiskMgr.getDiskMgr(diskName);
        return moveImage(dm, new File(dm.mainFolder,diskPath));
    }


    public synchronized ImageInfo moveImage(String destDisk, String destPath) throws Exception {
        DiskMgr.assertNoBackSlash(destPath);
        DiskMgr dm2 = DiskMgr.getDiskMgr(destDisk);
        return moveImage(dm2,new File(destPath));
    }

    public ImageInfo moveImage(DiskMgr dm2, File destFolder) throws Exception {
        
        if (dm2==null) {
            throw new JSONException("Null dm passed to moveImage!");
        }
        dm2.assertOnDisk(destFolder);
        String newFolderPath = dm2.getRelativePath(destFolder);
        File oldPath = getFilePath();
        String oldFolderPath = getFullPath();
        try {
            deleteThumbnails();
            if (!oldPath.exists()) {
                throw new JSONException("Image does not exist before move: {0}", oldPath);
            }
            if (dm2!=diskMgr || !destFolder.equals(oldPath))
            {
                PosPat.removeImage(this);
                pp = PosPat.findOrCreate(dm2, newFolderPath, getPattern());

                fileName = dm2.moveFileToDisk(diskMgr, oldFolderPath, fileName, destFolder);
                diskMgr = dm2;
                unsplit();
                initializeInternals(newFolderPath);

                // but, if not loaded, how to correct stats?
                PosPat.registerImage(this);
                
                //check that old one is gone
                if (oldPath.exists()) {
                    throw new JSONException("Image still exists in old location after move from {0} to {1}",oldPath,destFolder);
                }
            }

            File newFilePath = getFilePath();
            if (!newFilePath.exists()) {
                throw new JSONException("new image path does not exist after move: {0}",newFilePath);
            }
            
            return new ImageInfo(newFilePath, dm2);
        }
        catch (Exception e) {
            throw new JSONException("Unable to move image from ({0}) to ({1})",e, oldPath, destFolder);
        }
    }

    public void changePattern(String newPattern) throws Exception
    {
        if (getPattern().equals(newPattern))
        {
            return;  //already has that pattern
        }

        deleteThumbnails();

        int len = getPattern().length();
        String newName;

        //special case ... if the file did not have a number before
        //so we assumed zero for value, this will put a zero into
        //the new name
        String dummyNumber = "";
        if (value==0) {
            if (fileName.indexOf("0")<0) {
                dummyNumber = "00";
            }
        }

        // if it is an index, then an exclamation mark has been excluded
        // so add an exclamation mark to the new name.  This means that
        // an index will remain an index during change pattern.
        // Only way to change an index back to a normal file is through
        // rename, but since there are relatively few that is OK.
        if (isIndex) {
            if (newPattern.indexOf("!")==-1) {
                newName = newPattern+"!"+dummyNumber+fileName.substring(len+1);
            }
            else {
                newName = newPattern+dummyNumber+fileName.substring(len+1);
            }
        }
        else {
            newName = newPattern+dummyNumber+fileName.substring(len);
        }
        renameFile(newName);
        unsorted = true;
    }

    public synchronized void renameFile(String newName) throws Exception
    {
        String lcname = newName.toLowerCase();
        if (!lcname.endsWith(".jpg")) {
            newName = newName + ".jpg";
        }

        //avoid unnecessary updates
        if (fileName.equals(newName)) {
            return;  //already has that name
        }

        File folderPath = getFolderPath();
        String relPath = getRelativePath();

        newName = diskMgr.findSuitableName(folderPath, newName);

        //if there is going to be a problem, lets find out now, but this
        //should never happen now that we find a suitable name
        diskMgr.assertRenamePossible(folderPath, fileName, newName);

        PosPat.removeImage(this);
        deleteThumbnails();
        unsplit();

        diskMgr.renameDiskFile(folderPath, fileName, newName);
        fileName = newName;
        unsorted = true;
        initializeInternals(relPath);
        PosPat.registerImage(this);
    }

    public String renamePreserve(String newName) throws Exception
    {
        // strip the .jpg in case it is there
        String lcname = newName.toLowerCase();
        if (lcname.endsWith(".jpg")) {
            newName = newName.substring(0, newName.length()-4);
        }

        deleteThumbnails();
        int startpos = tail.indexOf('.')+1;
        StringBuffer newTail = new StringBuffer();
        while (startpos > 0 && startpos < fileName.length()-4) {
            int pos = tail.indexOf(".", startpos);
            if (pos < 0) {
                break;
            }
            newTail.append('.');
            newTail.append(tail.substring(startpos, pos));
            startpos = pos + 1;
        }

        String finalName = newName + newTail + ".jpg";
        renameFile(finalName);
        return finalName;
    }

    public int nextName(String newPatt, int num) throws Exception
    {
        deleteThumbnails();
        int startpos = tail.indexOf('.')+1;
        StringBuffer newTail = new StringBuffer();
        while (startpos > 0 && startpos < fileName.length()-4) {
            int pos = tail.indexOf(".", startpos);
            if (pos < 0) {
                break;
            }
            newTail.append('.');
            newTail.append(tail.substring(startpos, pos));
            startpos = pos + 1;
        }

        newTail.append(".jpg");
        String finalName = newPatt + Integer.toString(1000+num).substring(1) + newTail;
        while (diskMgr.fileExists(getFullPath(), finalName)) {
            num++;
            finalName = newPatt + Integer.toString(1000+num).substring(1) + newTail;
        }
        renameFile(finalName);
        return num+1;
    }

    public synchronized String insertGroup(String newGroup) throws Exception
    {
        deleteThumbnails();
        int startpos = tail.indexOf('.')+1;
        StringBuffer finalName = new StringBuffer();
        finalName.append(fileName.substring(0, fileName.length()-tail.length()+startpos-1));
        while (startpos > 0 && startpos < fileName.length()-4) {
            int pos = tail.indexOf(".", startpos);
            if (pos < 0) {
                break;
            }
            String oldGroup = tail.substring(startpos, pos);
            if (!oldGroup.equalsIgnoreCase(newGroup)) {
                finalName.append('.');
                finalName.append(oldGroup);
            }
            startpos = pos + 1;
        }

        finalName.append('.');
        finalName.append(newGroup);
        finalName.append(".jpg");
        renameFile(finalName.toString());
        return finalName.toString();
    }

    public synchronized void deleteThumbnails() throws Exception
    {
        File thumbFile = new File(DiskMgr.thumbPath,"100/"+diskMgr.diskName+"/"+getRelativePath()+fileName);
        if (thumbFile.exists()) {
            thumbFile.delete();
        }
        thumbFile = new File(DiskMgr.thumbPath,"350/"+diskMgr.diskName+"/"+getRelativePath()+fileName);
        if (thumbFile.exists()) {
            thumbFile.delete();
        }
    }


    public String getRelPath()
        throws Exception
    {
        if (diskMgr == null) {throw new JSONException("diskMgr is null");}

        StringBuffer result = new StringBuffer(diskMgr.diskName);
        result.append("/");
        result.append(getRelativePath());
        result.append(URLEncoder.encode(fileName, "UTF-8").replace('+',' '));
        return result.toString();
    }


    public static Vector<ImageInfo> imageQuery(String query) throws Exception {
        MongoDB mongo = new MongoDB();
        JSONArray list = mongo.querySets(query);
        mongo.close();
        
        Vector<ImageInfo> res = new Vector<ImageInfo>();
        for (JSONObject set : list.getJSONObjectList()) {
            JSONArray images = set.getJSONArray("images");
            for (JSONObject image : images.getJSONObjectList()) {
                ImageInfo ii = ImageInfo.genFromJSON(image);
                res.add(ii);
            }
        }
        return res;
    }    
    


    /****************  HELPER CLASSES  ***********************/

    static class StringComparator implements Comparator<String>
    {
        public StringComparator() {}

        public int compare(String o1, String o2)
        {
            return o1.compareToIgnoreCase(o2);
        }
    }

    static class ImagesByNameComparator implements Comparator<ImageInfo>
    {
        public ImagesByNameComparator() {}

        public int compare(ImageInfo o1, ImageInfo o2)
        {
            int res = o1.fileName.compareToIgnoreCase(o2.fileName);
            if (res != 0) {
                return res;
            }
            res = o1.diskMgr.diskName.compareToIgnoreCase(o2.diskMgr.diskName);
            if (res != 0) {
                return res;
            }
            res = o1.getRelativePath().compareToIgnoreCase(o2.getRelativePath());
            return res;
        }
    }

    static class ImagesByPathComparator implements Comparator<ImageInfo>
    {
        public ImagesByPathComparator() {}

        public int compare(ImageInfo o1, ImageInfo o2)
        {
            int res = o1.diskMgr.diskName.compareToIgnoreCase(o2.diskMgr.diskName);
            if (res != 0) {
                return res;
            }
            res = o1.getRelativePath().compareToIgnoreCase(o2.getRelativePath());
            if (res != 0) {
                return res;
            }
            res = o1.fileName.compareToIgnoreCase(o2.fileName);
            return res;
        }
    }

    static class ImagesByNumComparator implements Comparator<ImageInfo>
    {
        public ImagesByNumComparator() {}

        public int compare(ImageInfo o1, ImageInfo o2)
        {
            if (o1.value > o2.value) {
                return 1;
            }
            if (o1.value < o2.value) {
                return -1;
            }
            int res = o1.fileName.compareToIgnoreCase(o2.fileName);
            if (res != 0) {
                return res;
            }
            res = o1.diskMgr.diskName.compareToIgnoreCase(o2.diskMgr.diskName);
            return res;
        }
    }

    static class ImagesBySizeComparator implements Comparator<ImageInfo>
    {
        public ImagesBySizeComparator() {}

        public int compare(ImageInfo o1, ImageInfo o2)
        {
            if (o1.fileSize > o2.fileSize) {
                return -1;
            }
            if (o1.fileSize < o2.fileSize) {
                return 1;
            }
            return 0;
        }
    }

    static class ImagesRandomizer implements Comparator<ImageInfo>
    {
        public ImagesRandomizer() {}

        public int compare(ImageInfo o1, ImageInfo o2)
        {
            int thisVal = o1.randomValue;
            int anotherVal = o2.randomValue;
            return (thisVal<anotherVal ? -1 : (thisVal==anotherVal ? 0 : 1));
        }
    }
    
    public static ImageInfo genFromJSON(JSONObject image) throws Exception {
        String disk = image.getString("disk");
        DiskMgr dm = DiskMgr.getDiskMgr(disk);
        String path = image.getString("path");
        String fileName = image.getString("fileName");
        File parentFolder = dm.getFilePath(path);
        File fullPath = new File(parentFolder, fileName);
        
        ImageInfo ii = new ImageInfo(fullPath, dm);
        if (image.has("random")) {
            ii.randomValue = image.getInt("random");
        }
        return ii;
    }

    

    public JSONObject getJSON() throws Exception {
        JSONObject wholeDoc = getMinimalJSON();
        wholeDoc.put("disk", pp.getDiskMgr().diskName);
        
        wholeDoc.put("path", pp.getLocalPath());
        wholeDoc.put("pattern", pp.getPattern());
        wholeDoc.put("random", randGen.nextInt(1000000000));

        JSONArray tags = new JSONArray();
        for (String oneTag : tagNames) {
            tags.put(oneTag);
        }
        wholeDoc.put("tags", tags);
        return wholeDoc;
    }
    public JSONObject getMinimalJSON() throws Exception {
        JSONObject wholeDoc = new JSONObject();
        wholeDoc.put("fileName", fileName);
        wholeDoc.put("value", value);
        wholeDoc.put("fileSize", fileSize);
        return wholeDoc;
    }
    
}
