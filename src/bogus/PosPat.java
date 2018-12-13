package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import com.purplehillsbooks.json.JSONException;

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
    private static List<PosPat> ppIndex = new ArrayList<PosPat>();
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

    
    public Vector<String> getTags() {
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

    public int incrementImageCount() {
        return ++imageCount;
    }
    public int decrementImageCount() {
        return --imageCount;
    }
    public void setImageCount(int val) {
        imageCount = val;
    }

    //requests tend to come repeatedly for the same item in a row, so it is
    //worth holding on to that to check again.
    private static PosPat lastFound = null;

    public static synchronized PosPat findExisting(DiskMgr _dm, String _localPath, String _pattern) {

        //requests tend to come repeatedly for the same item in a row, so
        //check first to see if this request is for the same element again
        if (lastFound!=null && _dm.equals(lastFound.getDiskMgr())
                && _localPath.equals(lastFound.getLocalPath())
                && _pattern.equals(lastFound.getPattern()) ) {
            return lastFound;
        }

        int pos = findFirstEntryWithPattern(ppIndex, _pattern);
        while (true) {
            if (pos>=ppIndex.size()) {
                return null;
            }
            PosPat pp = ppIndex.get(pos);
            int comp = _pattern.compareToIgnoreCase(pp.pattern);
            if (comp<0) {
                //no more entries with this pattern, nothing found
                return null;
            }
            if (_pattern.equalsIgnoreCase(pp.pattern) &&
                    _localPath.equalsIgnoreCase(pp.localPath) &&
                    _dm == pp.diskMgr) {
                lastFound = pp;
                return pp;
            }
            pos++;
        }
    }

    public static synchronized PosPat findOrCreate(DiskMgr _dm, String _localPath, String _pattern) throws Exception {

        if (!_localPath.endsWith("/")) {
            //should we complain?  Or just fix it up?
            //_localPath = _localPath + "/";
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: ("+_localPath+")");
        }

    	
    	int pos = findFirstEntryWithPattern(ppIndex, _pattern);

        if(pos>0) {
            PosPat doubleCheck = ppIndex.get(pos-1);
            if ( doubleCheck.pattern.equalsIgnoreCase(_pattern) ) {
                throw new JSONException("findFirstEntryWithPattern did not succeed in finding the first entry with pattern ({0})",_pattern);
            }
        }

        while (pos<ppIndex.size()) {
            PosPat pp = ppIndex.get(pos);
            int compPatt = _pattern.compareToIgnoreCase(pp.pattern);
            int compPath = _localPath.compareToIgnoreCase(pp.localPath);
            int compDisk = _dm.diskName.compareToIgnoreCase(pp.diskMgr.diskName);
            if (compPatt<0) {
                //no more entries with this pattern, nothing found
                return insertWithoutSorting(_dm, _localPath, _pattern, pos);
            }
            if (compPatt>0) {
                throw new JSONException("Should never happen, got a pattern '{0}' that is lower than '{1}'", pp.pattern, _pattern);
            }
            //for everything else (comp==0) below, means that the patterns equals

            if (compPath>0) {
                //ignore paths that are lower and go to next
            }
            else if (compPath<0) {
                //found a path that is higher, insert new one here
                return insertWithoutSorting(_dm, _localPath, _pattern, pos);
            }
            else {
                // compPath is 0 means the path equals
                if (compDisk==0) {
                    //found an exact match, return it, don't create anything
                    return pp;
                }
                if (compDisk>0) {
                    //ignore disks that are lower
                }
                else {
                    //found a disk higher, so this is the place to insert
                    return insertWithoutSorting(_dm, _localPath, _pattern, pos);
                }
            }
            pos++;
        }

        //reached the end of the index, so add new on at end
        return addWithoutSorting(_dm, _localPath, _pattern);
    }

   public static synchronized PosPat findOrCreate0(DiskMgr _dm, String _localPath, String _pattern) throws Exception {
        PosPat pp = findExisting(_dm, _localPath, _pattern);
        if (pp==null) {
            pp = addWithoutSorting(_dm, _localPath, _pattern);
            sortIndex();
        }
        return pp;
    }


    public static synchronized PosPat addWithoutSorting(DiskMgr _dm, String _localPath, String _pattern)  {
        PosPat pp = new PosPat(_dm, _localPath, _pattern);
        ArrayList<PosPat> newList = new ArrayList<PosPat>();
        for (PosPat existing: ppIndex) {
            newList.add(existing);
        }
        newList.add(pp);
        ppIndex = newList;
        return pp;
    }
    private static synchronized PosPat insertWithoutSorting(DiskMgr _dm, String _localPath,
            String _pattern, int pos) throws Exception {

    	if (!_localPath.endsWith("/")) {
            //should we complain?  Or just fix it up?
            //_localPath = _localPath + "/";
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: ("+_localPath+")");
        }

        //test code
        PosPat doubleCheck = ppIndex.get(pos);
        if ( doubleCheck.diskMgr.diskName.equalsIgnoreCase(_dm.diskName)
                && doubleCheck.localPath.equalsIgnoreCase(_localPath)
                && doubleCheck.pattern.equalsIgnoreCase(_pattern) ) {
            throw new JSONException("Attempt to insert BEFORE an element that is identical");
        }
        if (pos>0) {
            doubleCheck = ppIndex.get(pos-1);
            if ( doubleCheck.diskMgr.diskName.equalsIgnoreCase(_dm.diskName)
                    && doubleCheck.localPath.equalsIgnoreCase(_localPath)
                    && doubleCheck.pattern.equalsIgnoreCase(_pattern) ) {
                throw new JSONException("Attempt to insert AFTER an element that is identical");
            }
        }

        //this is an attempt to insert without ever modifying and existing index
        //instead, create a new one.
        PosPat pp = new PosPat(_dm, _localPath, _pattern);
        ArrayList<PosPat> newList = new ArrayList<PosPat>();
        int count = 0;
        for (PosPat existing : ppIndex) {
            if (pos == count++) {
                newList.add(pp);
            }
            newList.add(existing);
        }
        //handle the add-on-the-end case
        if (pos == count++) {
            newList.add(pp);
        }
        ppIndex = newList;
        return pp;
    }

    public static synchronized void registerImage(ImageInfo ii) throws Exception {
        PosPat pp = findOrCreate(ii.diskMgr, ii.getRelativePath(), ii.getPattern());
        for (String aGroup : ii.getTagNames()) {
            pp.addTag(aGroup);
        }
        pp.incrementImageCount();
    }
    public static synchronized void registerImages(List<ImageInfo> iiList) throws Exception {
        for (ImageInfo ii : iiList) {
            PosPat pp = findExisting(ii.diskMgr, ii.getRelativePath(), ii.getPattern());
            if (pp==null) {
                pp = new PosPat(ii.diskMgr, ii.getRelativePath(), ii.getPattern());
                ppIndex.add(pp);
            }
            for (String aGroup : ii.getTagNames()) {
                pp.addTag(aGroup);
            }
            pp.incrementImageCount();
        }
        sortIndex();
    }
    public static synchronized void removeImage(ImageInfo ii) throws Exception {
        PosPat pp = findExisting(ii.diskMgr, ii.getRelativePath(), ii.getPattern());
        if (pp==null) {
            throw new JSONException("Why remove an image that is not in the index!: {0}",ii.getPatternSymbol());
        }
        for (String aGroup : ii.getTagNames()) {
            pp.removeTag(aGroup);
        }
        if (pp.decrementImageCount()<=0) {
            ppIndex.remove(pp);
        }
    }

    /**
     * clear everything out for garbage collection
     */
    public static void clearAllCache() {
        ppIndex = new Vector<PosPat>();
    }

    /**
     * Find all PosPat objects with a given pattern
     */
    public static List<PosPat> findAllPattern(String _pattern) {
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
    }

    /**
     * Find all PosPat objects with a given pattern
     */
    public static int countAllPatternOnDisk(DiskMgr dm, String _pattern) {
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
    }


    private static int findFirstEntryWithPattern(List<PosPat> vec, String term) {

        int low = 0;
        int high = vec.size();

        //if the vector is empty, then treat this like the search name is
        //greater than all, and return the vector size (zero, not a valid index)
        if (high==0) {
            return 0;
        }

        while (high-low > 5) {
            int mid = (high+low)/2;
            PosPat test = vec.get(mid);
            int comp = term.compareToIgnoreCase(test.pattern);

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
        PosPat test2 = vec.get(low);
        int comp2 = term.compareToIgnoreCase(test2.pattern);

        //the found image has a greater or equal name, so search backward
        while (comp2<=0) {
            if (low==0) {
                return 0;
            }
            low--;
            test2 = vec.get(low);
            comp2 = term.compareToIgnoreCase(test2.pattern);
        }

        //the found image has lower name, so search forward to one
        //either equal or greater
        while (comp2>0) {
            low++;
            if (low==vec.size()) {
                return low;
            }
            test2 = vec.get(low);
            comp2 = term.compareToIgnoreCase(test2.pattern);
        }
        return low;
    }

    public static synchronized void removeAllFromDisk(DiskMgr dm) throws Exception {
        Vector<PosPat> newIndex = new Vector<PosPat>();
        for (PosPat pp : ppIndex) {
            if (!pp.diskMgr.equals(dm)) {
                newIndex.add(pp);
            }
        }
        ppIndex = newIndex;
        sortIndex();  //might not be needed, but just to be sure
    }
    
    public static synchronized void removeAllDiskPath(DiskMgr dm, String relPath) throws Exception {
        if (!relPath.endsWith("/")) {
            //should we complain?  Or just fix it up?
            //_localPath = _localPath + "/";
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: "+relPath);
        }
        Vector<PosPat> newIndex = new Vector<PosPat>();
        for (PosPat pp : ppIndex) {
            if (!pp.diskMgr.equals(dm)) {
                newIndex.add(pp);
            }
            else if (!relPath.equalsIgnoreCase(pp.localPath)) {
            	newIndex.add(pp);
            }
        }
        ppIndex = newIndex;
        sortIndex();  //might not be needed, but just to be sure
    }

    public static synchronized void sortIndex() throws Exception {
        PosPatComparator sc = new PosPatComparator();
            Collections.sort(ppIndex, sc);
        }

    public static List<PosPat> getAllEntries() {
        return ppIndex;
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


}
