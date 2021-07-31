package com.purplehillsbooks.photegrity;

@SuppressWarnings("serial")
public class MarkedVector extends java.util.Vector<ImageInfo> {

    private int markPos = -1;

    public MarkedVector() {
        super();
    }

    /**
     * negative one means "no mark" When no mark, then add to end of vector
     */
    public void insertAtMark(ImageInfo obj) {
        normalizeMark();
        if (markPos >= 0) {
            super.insertElementAt(obj, markPos);
            markPos++;
        }
        else {
            super.add(obj);
        }
    }

    public void insertElementAt(ImageInfo obj, int index) {
        normalizeMark();
        if (index <= markPos) {
            markPos++;
        }
        super.insertElementAt(obj, index);
    }

    public void removeElementAt(int index) {
        normalizeMark();
        if (index < markPos) {
            markPos--;
        }
        super.removeElementAt(index);
    }

    public ImageInfo remove(int index) {
        normalizeMark();
        if (index < markPos) {
            markPos--;
        }
        if (index == markPos) {
            markPos = -1;
        }
        return super.remove(index);
    }

    public void moveToMark(int pos) {
        ImageInfo temp = elementAt(pos);
        removeElementAt(pos);
        insertAtMark(temp);
    }

    public void clear() {
        markPos = -1;
        super.clear();
    }

    public int getMarkPosition() {
        return markPos;
    }

    public void setMarkPosition(int pos) {
        markPos = pos;
        normalizeMark();
    }

    /**
     * a lot of the default operations on Vector will manipulate the size, so
     * make sure that the markPos is still valid.
     */
    private void normalizeMark() {
        if (markPos < 0 || markPos >= size()) {
            markPos = -1;
        }
    }

}