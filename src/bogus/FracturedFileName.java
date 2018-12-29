package bogus;

import java.io.File;


/**
 * breaks a file name into parts
 * 
 *  AA4XXXX    007   .jpg
 *  -------    ---   ----
 *  
 *  prePart,  numPart, tailPart
 *  
 *  The numpart is the LAST number in the file name.  
 *  This number can be normalized to be three digits
 *  so the number is from 0 to 999
 *  
 *  For negative numbers, us an exclamation point:
 *  
 *  JerseyShore   !03  .jpg
 *  -----------   ---  ----
 *  
 *  That would be the value for negative 3, we can't use
 *  hyphen because hyphens are used often in file names
 *  just before numbers.  The bang indicates negative.
 *  
 */
public class FracturedFileName {
    
    public String prePart = nullString;
    public String numPart = nullString;
    public String tailPart = nullString;
    
    private static String nullString = "";
    
    public static FracturedFileName parseFile(String fileName) {
        FracturedFileName ffn = new FracturedFileName();

        //if a null string was passed in, remain well behaved
        if (fileName==null) {
            return ffn;
        }
        if (fileName.length()<4) {
            ffn.prePart = fileName;
            return ffn;
        }
        // Now get the pattern from the file name
        // find the last numeral
        int pos = fileName.length() - 4;
        char ch = fileName.charAt(pos);
        while (pos > 0 && (ch < '0' || ch > '9')) {
            pos--;
            ch = fileName.charAt(pos);
        }

        //handle the case where no numeral was found at all, we just
        //split the file extension as the tail, and everything else pattern
        if (pos==0) {
            ffn.numPart = "";
            pos = fileName.lastIndexOf(".");
            if (pos>=0) {
                ffn.prePart = fileName.substring(0,pos);
                ffn.tailPart = fileName.substring(pos);
                return ffn;
            }

            //handle case where there is no period at all
            ffn.prePart = fileName;
            ffn.tailPart = "";
            return ffn;
        }

        // now, attempt to recognize and ignore file names with a hyphen-numeral
        // at the end. For example, best6789.jpg equals best6789-1.jpg
        if (pos > 3) {
            char tch = fileName.charAt(pos - 2);
            if (fileName.charAt(pos - 1) == '-' && (tch >= '0' && tch <= '9')) {
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

        // special case
        if (ch < '0' || ch > '9') {
            pos++;
        }

        // trim the exclamation mark if this is a negative, note that this
        // works only if the exclamation is just before the number.
        // Exclamation in other positions will lead to a separate, unique pattern
        if (pos > 0) {
            ch = fileName.charAt(pos - 1);
            if ('!' == ch) {
                pos--;
            }
        }

        ffn.prePart = fileName.substring(0, pos);
        ffn.numPart = fileName.substring(pos, tailBegin);
        ffn.tailPart = fileName.substring(tailBegin);
        return ffn;
    }

    public static FracturedFileName parseTemplate(String template) {
        FracturedFileName ffn = new FracturedFileName();
        int lastDollarPos = template.lastIndexOf("$");
        if (lastDollarPos>=0) {
            ffn.prePart = template.substring(0,lastDollarPos);
            ffn.numPart = template.substring(lastDollarPos,lastDollarPos+2);
            ffn.tailPart = template.substring(lastDollarPos+2);
        }
        else {
            ffn.prePart = template;
        }
        return ffn;
    }
    
    public FracturedFileName copy() {
        FracturedFileName ret = new FracturedFileName();
        ret.prePart = prePart;
        ret.numPart = numPart;
        ret.tailPart = tailPart;
        return ret;
    }
    
    public int getAbsValue() {
        return UtilityMethods.safeConvertInt(numPart);
    }
    public boolean isNegative() {
        return numPart.startsWith("!");
    }
    
    public String getBasicName() {
        return prePart + numPart + tailPart;
    }
    public String getRegularName() {
        if (numPart.length()==0) {
            return prePart + tailPart;
        }
        int val = getAbsValue();
        if (isNegative()) {
            return String.format("%s!%02d%s", prePart, val, tailPart);
        }
        else {
            return String.format("%s%03d%s", prePart, val, tailPart);
        }
    }
    
    public boolean isEmpty() {
        return prePart.length()==0 && numPart.length()==0 && tailPart.length()==0;
    }
    public boolean equals(FracturedFileName other) {
        if (other==null) {
            return false;
        }
        return prePart.equals(other.prePart) && numPart.equals(other.numPart) && tailPart.equals(other.tailPart);
    }
    
    /*
     * Returns the name of a file in the folder that exists,
     * otherwise the nice formatted regular name.
     */
    public File getBestPath(File destfolder) {
        String possibleName = existsAs(destfolder);
        if (possibleName!=null) {
            return new File(destfolder, possibleName);
        }
        else {
            return new File(destfolder, getRegularName());
        }
    }
    
    
    /*
     * There are three forms for a file with a single digit number:
     * 
     *      pattern1.jpg
     *      pattern01.jpg
     *      pattern001.jpg
     *      
     * For numbers >= 10 there are only two
     * For numbers >= 100 there is only one form
     * 
     * Test all the forms to see if one exists, and return the form.
     */
    public String existsAs(File folder) {
        //first try the regular case
        String trialName = getRegularName();
        File trialFile = new File(folder,trialName);
        if (trialFile.exists()) {
            return trialName;
        }
        int val = getAbsValue();
        if (val>=100) {
            return null;
        }
        trialName = String.format("%s%d%s", prePart, val, tailPart);
        trialFile = new File(folder,trialName);
        if (trialFile.exists()) {
            return trialName;
        }
        if (val>=10) {
            return null;
        }
        trialName = String.format("%s%02d%s", prePart, val, tailPart);
        trialFile = new File(folder,trialName);
        if (trialFile.exists()) {
            return trialName;
        }
        return null;
    }
    
    public void biasTheNumber(int bias) {
        if (bias==0) {
            return;
        }
        int val = getAbsValue();
        if (isNegative()) {
            numPart = String.format("!%02d", val+bias);
        }
        else {
            numPart = String.format("%03d", val+bias);
        }
    }
    
    public String toString() {
        return prePart + numPart + tailPart;
    }
    
    /**
     * If this is a file in a set of files, this will return the index
     * number of that file
     */
    public int getSequenceNumber() {
        int num = getAbsValue();
        if (num == 0) {
            if (tailPart.contains("cover")) {
                return -100;
            }
            if (tailPart.contains("flogo")) {
                return -200;
            }
            if (tailPart.contains("sample")) {
                return -300;
            }
            return 0;
        }
        if (isNegative()) {
            return 0 - num;
        }
        return num;
    }
    
}
