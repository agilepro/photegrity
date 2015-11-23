package bogus;

import java.io.File;
import java.net.URLEncoder;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Random;
import java.util.Vector;

public class ImageInfo
{
    public PosPat  pp;  //holds disk and rel path and pattern info

    public DiskMgr diskMgr;  // this image is in this collection

    public String  fileName; // the original and actual filename
    public int     value;    // numeric value of this file name
    public String  tail;     // rest of the file name after the number

    public int    fileSize;
    public Vector<TagInfo> tagVec;
    public int    randomValue;

    public boolean isIndex = false;
    public boolean isTrashed = false;

    public static Vector<ImageInfo> imagesByName;
    public static boolean unsorted = true;
    private static Vector<ImageInfo> imagesByPath;
    private static Vector<ImageInfo> imagesBySize;
    private static Vector<ImageInfo> imagesByNum;
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
            tagVec = new Vector<TagInfo>();
            randomValue = randGen.nextInt(1000000000);

            fileName = filePath.getName();
            fileSize = (int) filePath.length();

            File parentFolder = filePath.getParentFile();
            String relativePath = diskMgr.getRelativePath(parentFolder);

            initializeInternals(relativePath);
        }
        catch (Exception e) {
            throw new Exception2("Unable to create image info for "+filePath, e);
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
        tagVec = new Vector<TagInfo>();
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


    public static synchronized Vector<ImageInfo> getImagesByName()
        throws Exception
    {
        if (imagesByName == null) {
            imagesByName = new Vector<ImageInfo>();
            pathCompressor = new Hashtable<String, String>();
            unsorted = false;
            return imagesByName;
        }
        if (unsorted) {
            ImagesByNameComparator sc1 = new ImagesByNameComparator();
            Collections.sort(imagesByName, sc1);
            unsorted = false;
        }
        return imagesByName;
    }


    public static synchronized Vector<ImageInfo> getImagesBySize()
        throws Exception
    {
        if (imagesBySize != null) {
            return imagesBySize;
        }

        Vector<ImageInfo> v = new Vector<ImageInfo>();
        for (ImageInfo ii : getImagesByName()) {
            v.add( ii );
        }

        ImagesBySizeComparator sc3 = new ImagesBySizeComparator();
        Collections.sort(v, sc3);
        imagesBySize = v;
        return v;
    }


    public static synchronized Vector<ImageInfo> getImagesByNumber() throws Exception {
        if (imagesByNum != null) {
            return imagesByNum;
        }

        Vector<ImageInfo> v = new Vector<ImageInfo>();
        for (ImageInfo ii : getImagesByName()) {
            v.add(ii);
        }

        Collections.sort(v, new ImagesByNumComparator());
        imagesByNum = v;
        return v;
    }

    public static void sortImagesByName(Vector<ImageInfo> images)
        throws Exception
    {
        ImagesByNameComparator sc = new ImagesByNameComparator();
        Collections.sort(images, sc);
    }

    public static void sortImagesByPath(Vector<ImageInfo> images)
        throws Exception
    {
        ImagesByPathComparator sc = new ImagesByPathComparator();
        Collections.sort(images, sc);
    }

    public static void sortImagesBySize(Vector<ImageInfo> images)
        throws Exception
    {
        ImagesBySizeComparator sc = new ImagesBySizeComparator();
        Collections.sort(images, sc);
    }

    public static void sortImagesByNum(Vector<ImageInfo> images)
        throws Exception
    {
        ImagesByNumComparator sc = new ImagesByNumComparator();
        Collections.sort(images, sc);
    }

    public static void sortImages(Vector<ImageInfo> images, String order)
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
            throw new Exception("I don't understand how to sort by '"+order
                 +"'.  Please request a sort by path, size, num, rand, name, or none.");
        }
        Collections.sort(images, sc);
    }

    public static synchronized Vector<ImageInfo> getImagesByPath()
        throws Exception
    {
        if (imagesByPath != null) {
            return imagesByPath;
        }

        Vector<ImageInfo> v = new Vector<ImageInfo>();
        for (ImageInfo ii : getImagesByName()) {
            v.add( ii );
        }

        ImagesByPathComparator sc2 = new ImagesByPathComparator();
        Collections.sort(v, sc2);
        imagesByPath = v;
        return imagesByPath;
    }


    /********************************************************/


    public void unsplit() throws Exception
    {
        if (tail == null) {
            return;
        }
        for (TagInfo tag : tagVec) {
            tag.removeImage(this);
        }
        tagVec.clear();
        tail = null;
    }

    private String initializeInternals(String relPath) throws Exception
    {
        if (tail != null) {
            throw new Exception("Hmmm, realSplitIntoPatterns method is being called twice?");
        }
        try {
            if (diskMgr == null) {
                throw new Exception("diskMgr member is null, on image "
                                    +fileName+", relPath="+relPath);
            }
            if (relPath == null) {
                throw new Exception("Problem with initialization, relPath is null");
            }

            String[] parts = getFileNameParts(fileName);

            String tmpPattern = parts[0];
            int exclaimPos = tmpPattern.indexOf('!');  //remove the bang if there is one
            int coverPos = fileName.indexOf(".cover.");  //see if cover
            int flogoPos = fileName.indexOf(".flogo.");  //see if cover
            int samplePos = fileName.indexOf(".sample.");  //see if cover
            if (exclaimPos>=0) {
                isIndex = true;
                tmpPattern = tmpPattern.substring(0,exclaimPos) + tmpPattern.substring(exclaimPos+1);
            }
            pp = PosPat.findOrCreate(diskMgr, relPath, tmpPattern);

            value = UtilityMethods.safeConvertInt(parts[1]);
            if (coverPos>0) {
                value = -100;
            }
            else if (flogoPos>0) {
                value = -200;
            }
            else if (samplePos>0) {
                value = -300;
            }
            else if (isIndex) {
                value = -value;
            }

            tail = parts[2];

            determineTags();
            return tmpPattern;
        }
        catch (Exception e) {
            throw new Exception2("Unable to split into patterns ("+relPath+")("+fileName+")", e);
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
            TagInfo tag = TagInfo.findTag(scnTag);
            tag.addImage(this);
            tagVec.addElement(tag);
        }
    }
    
    private void wipeAllConnections() {
    	pp.decrementImageCount();
    	for (TagInfo tag : tagVec) {
    		tag.removeImage(this);
    	}
    }


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

    /**
     * Suggest using getFileNameParts unless you really really only
     * need the pattern part.
     */
    public static String patternFromFileName(String fileName) throws Exception
    {
        String[] parts = getFileNameParts(fileName);
        return parts[0];
    }

    /**
     * Given a file name, this routine will break it into three parts:
     * (1) the pattern (possibly including exclamation mark)
     * (2) the last numeric value, no more than 3 digits,
     *     and ignoring a hyphen and single digit number that some sites add
     *     when a image is duplicated.
     * (3) the tail, everything after the numeric value (including the hyphen
     *     digit if there was one.
     *
     * You can ALWAYS reassemble the original file name by concatenating
     * the three strings back together again.
     */
    public static String[] getFileNameParts(String fileName) {

        String[] parts = new String[3];

        // Now get the pattern from the file name
        // find the last numeral
        int pos = fileName.length() - 1;
        char ch = fileName.charAt(pos);

        //scan from the end of the fileName and look for last numeral
        while (pos > 0 && (ch < '0' || ch > '9')) {
            pos--;
            ch = fileName.charAt(pos);
        }

        //special case to handle when there are NO numerals in the file
        //name at all
        if (pos == 0) {
            parts[1] = "";  //numeric is blank
            int dotPos = fileName.indexOf(".");
            if (dotPos<0) {
                //here is the pathological case where there is no dot either
                parts[0] = fileName;
                parts[2] = "";  //tail is blank
            }
            else {
                parts[0] = fileName.substring(0, dotPos);
                parts[2] = fileName.substring(dotPos);
            }
            return parts;
        }


        // now, attempt to recognize and ignore file names with a hyphen-numeral
        // at the end. For example, best6789.jpg equals best6789-1.jpg
        if (pos > 3 && fileName.charAt(pos - 1) == '-') {
            char tch = fileName.charAt(pos - 2);
            if (tch >= '0' && tch <= '9') {
                pos = pos - 2;
                ch = tch;
            }
        }

        int tailBegin = pos + 1;

        int digitLimit = 2; // produces three digits max
        while (digitLimit > 0 && pos > 0 && ch >= '0' && ch <= '9') {
            pos--;
            digitLimit--;
            ch = fileName.charAt(pos);
        }

        // special case when there were fewer than 3 digits, have to add one back
        if (ch < '0' || ch > '9') {
            pos++;
        }

        parts[0] = fileName.substring(0, pos);
        parts[1] = fileName.substring(pos, tailBegin);
        parts[2] = fileName.substring(tailBegin);
        return parts;
    }

    public Vector<String> getTagNames()
        throws Exception
    {
        try {
            Vector<String> tagNames = new Vector<String>();
            for (TagInfo tag : tagVec) {
                tagNames.addElement(tag.tagName);
            }
            return tagNames;
        }
        catch (Exception ex) {
            throw new Exception2("getTagNames failed",ex);
        }
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
                    throw new Exception("Did not find the tab number "
                            +i+" in ("+start+") at pos="+pos);
                }
                result[i] = start.substring(pos, nextpos);
                pos = nextpos + 1;
            }
            result[expected-1] = start.substring(pos);
            return result;
        }
        catch (Exception e) {
            throw new Exception2("Error in splitString", e);
        }
    }


    static public void garbageCollect()
        throws Exception
    {
        // clear everything up front so that garbage collection will work
        imagesByPath = null;
        imagesBySize = null;
        imagesByName = null;
        pathCompressor = new Hashtable<String, String>();
        for (int i=0; i<memory.length; i++) {
            memory[i] = new MarkedVector();
        }

        // take care of peer classes
        TagInfo.garbageCollect();
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
                if (mgr.isChanged && mgr.isLoaded) {
                    mgr.writeSummary();
                }
            }
        }
        catch (Exception e) {
            throw new Exception2("Failure saving image info to allNames.txt", e);
        }
    }


    /**
     * remove all images from a particular disk
     */
    public static synchronized void removeDiskImages(DiskMgr dm) {
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
        unsorted = true;
    }

    /**
     * remove all images from a particular disk sitting at a
     * particular relative path
     */
    public static synchronized void removeDiskPath(DiskMgr dm, String relPath) throws Exception {
        Vector<ImageInfo> imagesForDisk = new Vector<ImageInfo>();
        if (imagesByName != null) {
            for (ImageInfo ii : imagesByName) {
                if (ii.diskMgr != dm) {
                    imagesForDisk.add(ii);
                }
                else if (!relPath.equalsIgnoreCase(ii.pp.getLocalPath())) {
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
        unsorted = true;
    }


    public static synchronized void acceptNewImages(Vector<ImageInfo> imagesForDisk)
    {
        imagesByPath = null;
        imagesBySize = null;
        imagesByNum  = null;
        if (imagesByName == null) {
            imagesByName = new Vector<ImageInfo>();
        }
        imagesByName.addAll(imagesForDisk);
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
                throw new Exception2("findImage was passed a null disk name");
            }
            if (originalFullPath == null) {
                throw new Exception2("findImage was passed a null originalFullPath");
            }
            DiskMgr dm = DiskMgr.getDiskMgr(disk);
            if (!dm.isLoaded) {
                throw new Exception2("the disk ("+disk+") is not loaded, can not find images on it");
            }
            String relPath = dm.convertFullPathToRelativePath(originalFullPath);
            return findImage2(disk, relPath, name);
        }
        catch (Exception e) {
            throw new Exception2("Unable to find an image (disk="+disk+")(originalFullPath="+originalFullPath+")(name="+name+")", e);
        }
    }

    /**
     * Finds the first image in the list with a name that is equal to or
     * greater than the search value.
     * Note: a name passed that is lower than all names, returns 0
     * a name passed greater than all names, returns vec.size (not a valid index!)
     */
    private static int findFirstImageWithName(Vector<ImageInfo> vec, String term) {

        int low = 0;
        int high = vec.size();

        //if the vector is empty, then treat this like the search name is
        //greater than all, and return the vector size (zero, not a valid index)
        if (high==0) {
            return 0;
        }

        while (high-low > 5) {
            int mid = (high+low)/2;
            ImageInfo test = vec.get(mid);
            int comp = term.compareToIgnoreCase(test.fileName);

            //  x.compareTo(y) return
            //  negative if x < y
            //  zero     if x=y
            //  positive if x > y

            if (comp==0) {
                low = mid;
                break;
            }
            if (comp<0) {
                high = mid;
            }
            else {
                low = mid;
            }
        }

        //low can be treated now as a starting point to find the exact
        //point that images with a particular name start
        ImageInfo test2 = vec.get(low);
        int comp2 = term.compareToIgnoreCase(test2.fileName);

        //the found image has a greater or equal name, so search backward
        while (comp2<=0) {
            if (low==0) {
                return 0;
            }
            low--;
            test2 = vec.get(low);
            comp2 = term.compareToIgnoreCase(test2.fileName);
        }

        //the found image has lower name, so search forward to one
        //either equal or greater
        while (comp2>0) {
            low++;
            if (low==vec.size()) {
                return low;
            }
            test2 = vec.get(low);
            comp2 = term.compareToIgnoreCase(test2.fileName);
        }
        return low;
    }



    public static ImageInfo findImage2(String disk, String relPath, String name)
        throws Exception
    {
        try {
            if (disk == null) {
                throw new Exception2("findImage was passed a null disk name");
            }
            if (relPath == null) {
                throw new Exception2("findImage was passed a null relPath");
            }
            if (name == null) {
                throw new Exception2("findImage was passed a null file name");
            }
            if (relPath.length()>0 && !relPath.endsWith("/")) {
                throw new Exception2("relPath must either be a null string, or it must end with a slash!  instead got: "+relPath);
            }
            Vector<ImageInfo> vFiles = getImagesByName();

            int last = vFiles.size();
            if (last == 0) {
                throw new Exception("Searched and not found because there are no images loaded, starting point :"+name);
            }
            int pos = findFirstImageWithName(vFiles, name);

            //if the file name is greater than all files in the list, handle that
            if (pos>=vFiles.size()) {
                throw new Exception2("the name ("+name+") is greater than all files in the index, nothing with that name");
            }

            int traceCount =  15;
            StringBuffer trace = new StringBuffer();
            trace.append("starting search with pos="+pos+" and last="+last+"\n");

            if (pos>0) {
                ImageInfo previous = vFiles.elementAt(pos-1);
                trace.append("prev: F("+previous.fileName+")D("+previous.diskMgr.diskName+")P("+previous.getRelativePath()+") \n");
                if (previous.fileName.equalsIgnoreCase(name)) {
                    throw new Exception("findFirstImageWithName failed to find the first index with name ("+name+") \n "+trace.toString());
                }
            }

            while (pos < last) {
                ImageInfo ii = vFiles.elementAt(pos);
                if (traceCount-- > 0) {
                    trace.append("img"+pos+": F("+ii.fileName+")D("+ii.diskMgr.diskName+")P("+ii.getRelativePath()+") \n");
                }
                int comp = name.compareToIgnoreCase(ii.fileName);

                //if the file has a name greater than searching for, we are done
                if (comp<0) {
                    throw new Exception("Searched and not found \n "+trace.toString());
                }
                if (disk.equalsIgnoreCase(ii.diskMgr.diskName) &&
                        relPath.equalsIgnoreCase(ii.getRelativePath()) &&
                        name.equalsIgnoreCase(ii.fileName)) {
                    return ii;
                }
                pos++;
            }
            throw new Exception("Searched through to end and not found \n "+trace.toString());
        }
        catch (Exception e) {
            throw new Exception2("Unable to find an image with disk="+disk+", relPath="+relPath+", name="+name, e);
        }
    }


    public static ImageInfo findFirstMatch(String disk, String relPath, String pattern, int val)
            throws Exception
        {
            try {
                if (disk == null) {
                    throw new Exception2("findImage was passed a null disk name");
                }
                if (relPath == null) {
                    throw new Exception2("findImage was passed a null relPath");
                }
                if (pattern == null) {
                    throw new Exception2("findImage was passed a null file name");
                }
                if (relPath.length()>0 && !relPath.endsWith("/")) {
                    throw new Exception2("relPath must either be a null string, or it must end with a slash!  instead got: "+relPath);
                }
                Vector<ImageInfo> vFiles = getImagesByName();

                int last = vFiles.size();
                if (last == 0) {
                    throw new Exception("Searched and not found because there are no images loaded, starting point :"+pattern);
                }
                int pos = findFirstImageWithName(vFiles, pattern);

                //if the file name is greater than all files in the list, handle that
                if (pos>=vFiles.size()) {
                    throw new Exception2("the pattern ("+pattern+") is greater than all files in the index, nothing with that name");
                }

                StringBuffer trace = new StringBuffer();
                trace.append("starting search with pos="+pos+" and last="+last+"\n");

                if (pos>0) {
                    ImageInfo previous = vFiles.elementAt(pos-1);
                    trace.append("prev: F("+previous.fileName+")D("+previous.diskMgr.diskName+")P("+previous.getRelativePath()+") \n");
                    if (pattern.equalsIgnoreCase(previous.pp.getPattern())) {
                        throw new Exception("findFirstImageWithName failed to find the first index with name ("+pattern+") \n "+trace.toString());
                    }
                }

                while (pos < last) {
                    ImageInfo ii = vFiles.elementAt(pos);
                    int comp = pattern.compareToIgnoreCase(ii.pp.getPattern());

                    //if the file has a pattern greater than searching for, we are done
                    if (comp<0) {
                        return null;
                    }
                    if (disk.equalsIgnoreCase(ii.diskMgr.diskName) &&
                            relPath.equalsIgnoreCase(ii.getRelativePath()) &&
                            pattern.equalsIgnoreCase(ii.pp.getPattern()) &&
                            val == ii.value) {
                        return ii;
                    }
                    pos++;
                }
                throw new Exception("Searched through to end and not found \n "+trace.toString());
            }
            catch (Exception e) {
                throw new Exception2("Unable to find an image with disk="+disk+", relPath="+relPath+", pattern="+pattern, e);
            }
        }

    public static List<ImageInfo> findAllMatching(String disk, String relPath, String pattern, int val)
            throws Exception
        {
            try {
                if (disk == null) {
                    throw new Exception2("findAllMatching was passed a null disk name");
                }
                if (relPath == null) {
                    throw new Exception2("findAllMatching was passed a null relPath");
                }
                if (pattern == null) {
                    throw new Exception2("findAllMatching was passed a null file name");
                }
                if (relPath.length()>0 && !relPath.endsWith("/")) {
                    throw new Exception2("for findAllMatching relPath must either be a null string, or it must end with a slash!  instead got: "+relPath);
                }
                Vector<ImageInfo> vFiles = new Vector<ImageInfo> ();
                for (ImageInfo ii : getImagesByName()){
                    if (ii.value == val && pattern.equalsIgnoreCase(ii.getPattern())
                            && relPath.equalsIgnoreCase(ii.getRelativePath())) {
                        vFiles.add(ii);
                    }
                }
                return vFiles;
            }
            catch (Exception e) {
                throw new Exception2("Error trying to find image for disk="+disk+", relPath="+relPath+", pattern="+pattern, e);
            }
        }

    public static ImageInfo findImageByKey(String key) throws Exception
    {
        try {
            if (key == null) {
                throw new Exception2("findImage was passed a null key");
            }
            int colonPos = key.indexOf(':');
            if (colonPos < 0) {
                throw new Exception("Can't find a colon in key: '"+key+"'");
            }
            int slashPos = key.lastIndexOf('/');
            if (slashPos < 0) {
                throw new Exception("Can't find a slash in key: '"+key+"'");
            }
            String disk    = key.substring(0, colonPos);
            String relPath = key.substring(colonPos+1, slashPos+1);
            String name    = key.substring(slashPos+1);
            Vector<ImageInfo> vFiles  = getImagesByName();

            int last = vFiles.size();
            if (last == 0) {
                throw new Exception("Searched and not found because there are no images loaded, starting point :"+name);
            }
            int pos = findFirstImageWithName(vFiles, name);

            // returns a negative if the exact match is not found
            // that is OK, we don't need an an exact match, so
            // use the index by negating it.
            if (pos < 0) {
                pos = -pos - 1;
            }

            // problem is that there may be multiple images with the same name, and
            // the binary search does not always find the first, so back up a bit
            // to be sure not to miss it.
            if (pos>10) {
                pos -= 10;
            }
            else {
                pos = 0;
            }

            ImageInfo ii2 = vFiles.elementAt(pos);
            String startName = ii2.fileName;

            while (pos < last) {
                ImageInfo ii = vFiles.elementAt(pos);
                if (disk.equals(ii.diskMgr.diskName) &&
                        name.equalsIgnoreCase(ii.fileName) &&
                        relPath.equalsIgnoreCase(ii.getRelativePath())) {
                    return ii;
                }
                pos++;
            }
            throw new Exception("Searched and not found, starting point: "+startName);
        }
        catch (Exception e) {
            throw new Exception2("Unable to find an image with key="+key, e);
        }
    }

    public static Vector<PatternInfo> getAllPatternsStartingWith(String start) throws Exception
    {
        try {
            Vector<ImageInfo> vFiles = getImagesByName();

            //the above does not work!  File names can have exclamations
            //markes in them, and they getstripped out of the pattern.
            //therefor the file names with the ! will sort in a different
            //order, and you will not find all of them.

            Vector<PatternInfo> vPatterns = new Vector<PatternInfo>();

            int last = vFiles.size();
            int pos = findFirstImageWithName(vFiles, start);

            // returns a negative if the exact match is not found
            // that is OK, we don'tneed an an exact match, so
            // use the index by negating it.
            if (pos < 0) {
                pos = -pos - 1;
            }

            String terminator = start + "ÿÿÿ";   //highest posible matching value...
            Hashtable<String, PatternInfo> map = new Hashtable<String, PatternInfo>();

            while (pos < last) {
                ImageInfo ii = vFiles.elementAt(pos);
                pos++;
                String lcpatt = ii.getPattern().toLowerCase();

                // stop after the last possible image
                if (lcpatt.compareToIgnoreCase(terminator) > 0) {
                    break;
                }

                PatternInfo pi = map.get(lcpatt);
                if (pi == null) {
                    pi = new PatternInfo(ii);
                    map.put(lcpatt, pi);
                    vPatterns.addElement(pi);
                }
                else {
                    pi.addImage(ii);
                }
            }
            return vPatterns;
        }
        catch(Exception e) {
            throw new Exception2("Error in getAllPatternsStartingWith("+start+")",e);
        }
    }


    /**
    * Searches the loaded images that have a particular pattern
    */
    public static Vector<ImageInfo> getImagesMatchingPattern(String searchPatt) throws Exception
    {
        try {
            Vector<ImageInfo> allImages = getImagesByName();
            Vector<ImageInfo> res = new Vector<ImageInfo>();
            for (ImageInfo ii : allImages) {
                if (ii.getPattern().equalsIgnoreCase(searchPatt)) {
                    res.add(ii);
                }
            }
            return res;
        }
        catch(Exception e) {
            throw new Exception2("Error in getImagesMatchingPattern("+searchPatt+")",e);
        }
    }


    public static Vector<PatternInfo> queryImages(String start) throws Exception
    {
        try {
            Vector<ImageInfo> vFiles = getImagesByName();
            Vector<PatternInfo> vPatterns = new Vector<PatternInfo>();

            int last = vFiles.size();
            int pos = findFirstImageWithName(vFiles, start);

            // returns a negative if the exact match is not found
            // that is OK, we don'tneed an an exact match, so
            // use the index by negating it.
            if (pos < 0) {
                pos = -pos - 1;
            }

            String terminator = start + "ÿÿÿ";   //highest posible matching value...
            Hashtable<String, PatternInfo> map = new Hashtable<String, PatternInfo>();

            while (pos < last) {
                ImageInfo ii = vFiles.elementAt(pos);
                pos++;

                // stop after the last possible image
                if (ii.fileName.compareToIgnoreCase(terminator) > 0) {
                    //System.out.println("getAllPatt: terminator ("+terminator+"): "+ii.fileName);
                    break;
                }

                String lcpatt = ii.getPattern().toLowerCase();
                PatternInfo pi = map.get(lcpatt);
                if (pi == null) {
                    pi = new PatternInfo(ii);
                    map.put(lcpatt, pi);
                    vPatterns.addElement(pi);
                }
                else {
                    pi.addImage(ii);
                }
            }
            return vPatterns;
        }
        catch(Exception e) {
            throw new Exception2("Error in queryImages("+start+")",e);
        }
    }





    // takes this image out of the collection of images.
    private void unPlugImage()
        throws Exception
    {
        if (imagesByName != null) {
            imagesByName.remove(this);
        }
        if (imagesByPath != null) {
            imagesByPath.remove(this);
        }
        if (imagesBySize != null) {
            imagesBySize.remove(this);
        }
        if (imagesByNum != null) {
            imagesByNum.remove(this);
        }
        // just in case this is part of a selection
        for (int i=0; i<memory.length; i++) {
            memory[i].remove(this);
        }

        for (TagInfo tag : tagVec) {
            tag.removeImage(this);
        }
    }


    public synchronized void suppressImage()
        throws Exception
    {
        //TODO: replace this with a File object
        String fullPath = getFullPath();
        try {
            PosPat.removeImage(this);

            diskMgr.suppressFile(fullPath, fileName);
            deleteThumbnails();

            for (TagInfo tag : tagVec) {
                diskMgr.decrementGroupCount(tag.tagName);
            }

            unPlugImage();

        } catch (Exception e) {
            throw new Exception2("Unable to suppress image "+fullPath+"/"+fileName,e);
        }
    }

    public synchronized void moveImageToLoc(String newLoc)
        throws Exception
    {
        DiskMgr.assertNoBackSlash(newLoc);
        int colonPos = newLoc.indexOf(":");
        String diskName = newLoc.substring(0, colonPos);
        String diskPath = newLoc.substring(colonPos+1);
        DiskMgr dm = DiskMgr.getDiskMgr(diskName);
        moveImage(dm, new File(dm.imageFolder,diskPath));
    }


    public synchronized void moveImage(String destDisk, String destPath)
        throws Exception
    {
        DiskMgr.assertNoBackSlash(destPath);
        DiskMgr dm2 = DiskMgr.getDiskMgr(destDisk);
        moveImage(dm2,new File(destPath));
    }

    public void moveImage(DiskMgr dm2, File destFolder)
        throws Exception
    {
        if (dm2==null) {
            throw new Exception("Null dm passed to moveImage!");
        }
        if (!dm2.isLoaded) {
            throw new Exception("You can't move to a disk ("+dm2.diskName+") that is not loaded...");
        }
        dm2.assertOnDisk(destFolder);
        String newFolderPath = dm2.getRelativePath(destFolder);
        File oldPath = getFilePath();
        String oldFolderPath = getFullPath();
        try {
            deleteThumbnails();
            if (!oldPath.exists()) {
                throw new Exception("Image does not exist before move: "+oldPath);
            }
            if (dm2!=diskMgr || !destFolder.equals(new File(oldFolderPath)))
            {
                PosPat.removeImage(this);
                eraseStats();
                pp = PosPat.findOrCreate(dm2, newFolderPath, getPattern());

                fileName = dm2.moveFileToDisk(diskMgr, oldFolderPath, fileName, destFolder);
                if (dm2.isLoaded)
                {
                    diskMgr = dm2;
                    unsplit();
                    initializeInternals(newFolderPath);

                    // but, if not loaded, how to correct stats?
                    recordStats();
                    PosPat.registerImage(this);
                }
                else
                {
                    unPlugImage();
                }
                //check that old one is gone
                if (oldPath.exists()) {
                    throw new Exception("Image still exists ini old location after move from "
                                +oldPath+" to "+destFolder);
                }
            }

            File newFilePath = getFilePath();
            if (!newFilePath.exists()) {
                throw new Exception("new image path does not exist after move: "+newFilePath);
            }
        }
        catch (Exception e) {
            throw new Exception("Unable to move image from ("+oldPath+") to ("+destFolder+")", e);
        }
    }

    // diskManager keeps statistics about grops and patterns
    // this tells a manager to forget about this image for now
    // usually because name or location is going to change
    public void eraseStats()
        throws Exception
    {
        for (TagInfo gi : tagVec) {
            diskMgr.decrementGroupCount(gi.tagName);
        }
    }

    // diskManager keeps statistics about grops and patterns
    // this tells a manager to record this image
    // done automatically at load time, this is only needed
    // if you previously erased stats about this image.
    public void recordStats()
        throws Exception
    {
        for (TagInfo tag : tagVec) {
            diskMgr.incrementGroupCount(tag.tagName);
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
        eraseStats();
        unsplit();

        diskMgr.renameDiskFile(folderPath, fileName, newName);
        fileName = newName;
        unsorted = true;
        initializeInternals(relPath);
        recordStats();
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
        File thumbFile = new File(diskMgr.thumbPath,"100/"+diskMgr.diskName+"/"+getRelativePath()+fileName);
        if (thumbFile.exists()) {
            thumbFile.delete();
        }
        thumbFile = new File(diskMgr.thumbPath,"350/"+diskMgr.diskName+"/"+getRelativePath()+fileName);
        if (thumbFile.exists()) {
            thumbFile.delete();
        }
    }


    public String getRelPath()
        throws Exception
    {
        if (diskMgr == null) {throw new Exception("diskMgr is null");}

        StringBuffer result = new StringBuffer(diskMgr.diskName);
        result.append("/");
        result.append(getRelativePath());
        result.append(URLEncoder.encode(fileName, "UTF-8").replace('+',' '));
        return result.toString();
    }


    public static Vector<ImageInfo> imageQuery(String query)
        throws Exception
    {
        try {

            if (query.length()<4) {
                throw new Exception("query is too short, must be letter, an open paren, at least one value char, and a close paren");
            }

            int pos = 0;
            char sel = query.charAt(0);

            if (query.charAt(1) != '(') {
                throw new Exception("error with query, second character must be an open paren");
            }

            pos = query.indexOf(')');
            if (pos<0) {
                throw new Exception("Error, can not find the closing paren char");
            }

            String val = query.substring(2, pos);

            Vector<ImageInfo> vImages = new Vector<ImageInfo>();
            switch (sel) {
                case 'g':
                    for( TagInfo tag:TagInfo.getAllTagsStartingWith(val)) {
                        if (tag.tagName.equalsIgnoreCase(val)) {
                            vImages.addAll(tag.allImages);
                        }
                    }
                    break;
                case 'p':
                    Vector<PatternInfo> vPatt = ImageInfo.getAllPatternsStartingWith(val);
                    for (PatternInfo pi : vPatt) {
                        if (pi.getPattern().equalsIgnoreCase(val)) {
                            vImages.addAll(pi.allImages);
                        }
                    }
                    break;
                case 's':
                    int numval = Integer.parseInt(val);
                    if (numval<1) {
                        throw new Exception("memory banks are numbered 1 thru "+MEMORY_SIZE+", and '"+numval+"' is too small.");
                    }
                    if (numval>MEMORY_SIZE) {
                        throw new Exception("memory banks are numbered 1 thru "+MEMORY_SIZE+", and '"+numval+"' is too large.");
                    }
                    vImages.addAll(ImageInfo.memory[numval-1]);
                    break;
                default:
                    throw new Exception("query elements must begin with a 'g', 'p', or 's'");
            }

            int startPos = pos+1;
            while (startPos<query.length()) {
                sel = query.charAt(startPos);
                if (query.charAt(startPos+1) != '(') {
                    throw new Exception("error with query, second character must be an open paren at position "+(startPos+1));
                }
                pos = query.indexOf(')', startPos+2);
                if (pos<0) {
                    throw new Exception("Error, can not find the closing paren char after position "+(startPos+2));
                }
                val = query.substring(startPos+2, pos);
                Vector<ImageInfo> oldGrp = vImages;
                vImages = new Vector<ImageInfo>();
                switch (sel) {
                    case 'g':   //tag
                        for (ImageInfo ii : oldGrp) {
                            Vector<String> gps = ii.getTagNames();
                            for (String gname : gps) {
                                if (gname.equalsIgnoreCase(val)) {
                                    vImages.add(ii);
                                    break;
                                }
                            }
                        }
                        break;
                    case 'p':   //pattern contains
                        for (ImageInfo ii : oldGrp) {
                            String pattName = ii.getPattern();
                            if (pattName.indexOf(val)>=0) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 's':   //pattern starts with
                        for (ImageInfo ii : oldGrp) {
                            String pattName = ii.getPattern();
                            if (pattName.indexOf(val)==0) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'e':   //pattern equals
                        for (ImageInfo ii : oldGrp) {
                            String pattName = ii.getPattern();
                            if (pattName.equalsIgnoreCase(val)) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'd':  //NOT tag
                        for (ImageInfo ii : oldGrp) {
                            Vector<String> gps = ii.getTagNames();
                            boolean notPresent = true;
                            for (String gname : gps) {
                                if (gname.startsWith(val)) {
                                    notPresent = false;
                                    break;
                                }
                            }
                            if (notPresent) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'b':   //NOT pattern contains
                        for (ImageInfo ii : oldGrp) {
                            String pattName = ii.getPattern();
                            if (pattName.indexOf(val)<0) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case '!':   //NOT index
                        for (ImageInfo ii : oldGrp) {
                            if (!ii.isIndex) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'i':   //index
                        for (ImageInfo ii : oldGrp) {
                            if (ii.isIndex) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 't':   //duplicate sizes
                        sortImagesBySize(oldGrp);
                        int lastSize=-1;
                        ImageInfo savei = null;
                        for (ImageInfo ii : oldGrp) {
                            if (ii.fileSize == lastSize) {
                                if (savei!=null) {
                                    vImages.add(savei);
                                    savei = null;
                                }
                                vImages.add(ii);
                            }
                            else {
                                savei = ii;
                                lastSize = ii.fileSize;
                            }
                        }
                        break;
                    case 'z':   //identical numbers
                        sortImagesByNum(oldGrp);
                        int lastVal=-999;
                        ImageInfo saven = null;
                        for (ImageInfo ii : oldGrp) {
                            if (ii.value == lastVal) {
                                if (saven!=null) {
                                    vImages.add(saven);
                                    saven = null;
                                }
                                vImages.add(ii);
                            }
                            else {
                                saven = ii;
                                lastVal = ii.value;
                            }
                        }
                        break;
                    case 'n':   //number range
                        int commapos = val.indexOf(",");
                        if (commapos < 0) {
                            throw new Exception("The 'n' query must have a lower integer, a comma, then an upper number to form a number range");
                        }
                        String lower = val.substring(0, commapos);
                        String higher = val.substring(commapos+1);
                        int ilower = Integer.parseInt(lower);
                        int ihigher = Integer.parseInt(higher);

                        for (ImageInfo ii : oldGrp) {
                            if (ii.value >= ilower && ii.value <= ihigher) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'u':   //number range
                        int numgrps = Integer.parseInt(val);

                        for (ImageInfo ii : oldGrp) {
                            if (ii.tagVec.size() == numgrps) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    case 'l':   //larger-than specified size
                        int minsize = Integer.parseInt(val);

                        for (ImageInfo ii : oldGrp) {
                            if (ii.fileSize >= minsize) {
                                vImages.add(ii);
                            }
                        }
                        break;
                    default:
                        throw new Exception("secondary query elements must begin with a 'g' for tag, "
                            +"'d' for NOT tag, 'p' for pattern contains, 'b' for pattern not contains, "
                            +"'s' pattern starts,  or 'e' for pattern exact, 't' for duplicate size, "
                            +"'i' for index, and '!' for NOT index, 'n' for numeric range, 'u' for number of tags,"
                            +"'l' for larger-than size");
                }
                startPos = pos+1;
            }
            //handle further restrictions here
            return vImages;
        }
        catch(Exception e) {
            throw new Exception2("Error in queryImages("+query+")",e);
        }
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



}
