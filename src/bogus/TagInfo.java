package bogus;

import java.io.Writer;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.Vector;

import com.purplehillsbooks.streams.HTMLWriter;

public class TagInfo {
    public String tagName;
    private String tagNameLC;
    public Vector<ImageInfo> allImages;
    public Hashtable<String, String> allDisks;

    public static Hashtable<String, TagInfo> allTags = new Hashtable<String, TagInfo>();

    public static TagInfo findTag(String name) throws Exception {
        String namelc = name.toLowerCase();
        TagInfo tag = allTags.get(namelc);
        if (tag != null) {
            return tag;
        }
        tag = new TagInfo(name);
        allTags.put(namelc, tag);
        return tag;
    }

    public static Vector<TagInfo> getAllTagsStartingWith(String start) throws Exception {
        try {
            if (start == null) {
                throw new Exception(
                        "a null string value was passed as the start parameter to getAllGroupsStartingWith.");
            }

            Vector<TagInfo> vSubGroups = new Vector<TagInfo>();
            String startlc = start.toLowerCase();

            for (TagInfo gi : allTags.values()) {
                if (gi.tagNameLC.startsWith(startlc)) {
                    vSubGroups.addElement(gi);
                }
            }

            Collections.sort(vSubGroups, new TagsComparator());
            return vSubGroups;
        }
        catch (Exception e) {
            throw new Exception2("Error in getAllGroupsStartingWith(" + start + ")", e);
        }
    }

    private TagInfo(String tname) throws Exception {
        if (tname == null) {
            throw new Exception("Attempt to create a tag with a null name -- not allowed");
        }
        if (tname.length() == 0) {
            throw new Exception("Attempt to create a tag with a 0 length name -- not allowed");
        }
        tagName = tname;
        tagNameLC = tname.toLowerCase();
        allImages = new Vector<ImageInfo>();
        allDisks = new Hashtable<String, String>();
    }

    public static void garbageCollect() {
        // throw away all knowledge of tags or other objects
        allTags = new Hashtable<String, TagInfo>();
    }

    public void addImage(ImageInfo ii) {
        allImages.addElement(ii);
        allDisks.put(ii.diskMgr.diskName, ii.diskMgr.diskName);
    }

    public void removeImage(ImageInfo ii) {
        allImages.remove(ii);
        // we don't clean up the disks member...
    }

    public int getCount() {
        return allImages.size();
    }

    static class TagsComparator implements Comparator<TagInfo> {
        public TagsComparator() {
        }

        public int compare(TagInfo o1, TagInfo o2) {
            return o1.tagName.compareToIgnoreCase(o2.tagName);
        }
    }


    public void writeLink(Writer out) throws Exception {
        out.write("<a href=\"group.jsp?g=");
        UtilityMethods.writeURLEncoded(out, tagName);
        out.write("\">");
        HTMLWriter.writeHtml(out, tagName);
        out.write("</a>");
    }
}