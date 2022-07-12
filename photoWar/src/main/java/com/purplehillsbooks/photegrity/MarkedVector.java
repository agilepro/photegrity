package com.purplehillsbooks.photegrity;

import java.util.List;
import java.util.Random;

@SuppressWarnings("serial")
public class MarkedVector extends java.util.ArrayList<ImageInfo> {

    private int     markPos = -1;
    public  String  name;
    public  String  id;

    public MarkedVector(String newName) {
        super();
        name = newName;
    }

    /**
     * negative one means "no mark" When no mark, then add to end of vector
     */
    public void insertAtMark(ImageInfo obj) {
        normalizeMark();
        if (markPos >= 0) {
            super.set(markPos, obj);
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
        super.set(index, obj);
    }

    public void removeElementAt(int index) {
        normalizeMark();
        if (index < markPos) {
            markPos--;
        }
        super.remove(index);
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
        ImageInfo temp = get(pos);
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
     * a lot of the default operations on ArrayList will manipulate the size, so
     * make sure that the markPos is still valid.
     */
    private void normalizeMark() {
        if (markPos < 0 || markPos >= size()) {
            markPos = -1;
        }
    }
    
    Random rand = new Random();
    public void pickUniqueId(List<MarkedVector> others) {
        while (true) {
            boolean found = false;
            StringBuilder sb = new StringBuilder();
            sb.append((char)(65+rand.nextInt(26)));
            sb.append((char)(65+rand.nextInt(26)));
            //sb.append((char)(65+rand.nextInt(26)));
            //sb.append((char)(65+rand.nextInt(26)));
            //sb.append((char)(65+rand.nextInt(26)));
            String trial = sb.toString();
            for (MarkedVector mv : others) {
                if (trial.equals(mv.id)) {
                    found = true;
                }
            }
            if (!found) {
                id = trial;
                return;
            }
        }
    }

}