package com.purplehillsbooks.photegrity;

public class LabCell {
    
    int walls;
    
    public boolean hasN() {
        return (walls % 2 == 1);
    }
    public boolean hasE() {
        return (walls/2 % 2 == 1);
    }
    public boolean hasS() {
        return (walls/4 % 2 == 1);
    }
    public boolean hasW() {
        return (walls/8 % 2 == 1);
    }
    
}
