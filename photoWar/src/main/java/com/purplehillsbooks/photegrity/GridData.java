package com.purplehillsbooks.photegrity;

import java.util.Collections;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Set;
import java.util.Vector;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class GridData {

    public String query = "";

    private Vector<ImageInfo> rawData = new Vector<ImageInfo>();
    private Vector<Vector<ImageInfo>> grid = new Vector<Vector<ImageInfo>>();
    private Hashtable<String, Object> selectedColumns = new Hashtable<String, Object>();

    /*
     * Retains the default image info for a particular column name
     */
    private Hashtable<String, ImageInfo> defImage = new Hashtable<String, ImageInfo>();

    /**
     * When you have a grid, there are a certain number of images per row.
     * totalPerRow is the number in the complete query on a row selectedPerRow
     * is the number in the selected set for a particular row valueMap is the
     * sorted array of number values that exist, either selected or not
     * depending on the current mode. This is used for scrolling vertically.
     */
    private NumericCounter totalPerRow = new NumericCounter();
    private HashCounter totalPerCol = new HashCounter();
    private NumericCounter selectedPerRow = new NumericCounter();
    private Vector<Integer> totalRowMap = new Vector<Integer>();
    private Vector<Integer> selectedRowMap = new Vector<Integer>();
    private boolean needsRecalc = true;

    /**
     * selMode == "all" means to display all columns selMode == "sel" means to
     * display only selected columns selMode == "unsel" means to display only
     * unselected columns
     */
    public String selMode = "all";

    /**
     * Indicates to display single row at a time, or 6 rows at a time.
     */
    public boolean singleRow = true;

    public int rangeTop = -999;
    public int rangeBottom = 999;

    public GridData() {
        needsRecalc = true;
    }

    public void setQuery(String newQuery) throws Exception {
        query = newQuery;
        flushCache();
    }

    public String getQuery() throws Exception {
        return query;
    }

    public Vector<String> getColumnMap() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return totalPerCol.getSortedKeys(selectedColumns);
    }

    public Vector<String> getColumnMapWithoutSelectionPrioritization() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return totalPerCol.sortedKeys();
    }

    public int numberInColumn(String colVal) {
        return totalPerCol.getCount(colVal);
    }

    public boolean isSelected(String colVal) {
        return (selectedColumns.get(colVal) != null);
    }

    public void toggleSelected(String colVal) {
        Object there = selectedColumns.get(colVal);
        if (there == null) {
            selectedColumns.put(colVal, colVal);
        }
        else {
            selectedColumns.remove(colVal);
        }
    }

    public Vector<Integer> getRowMap() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return totalRowMap;
    }

    public Vector<Integer> getSelectedRowMap() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return selectedRowMap;
    }

    public Hashtable<String, Object> getSelectedColumns() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return selectedColumns;
    }

    /**
     * if column is selected, then make it unselected. If not selected, then
     * select it.
     */
    public void toggleColumn(String cval) throws Exception {
        Object there = selectedColumns.get(cval);
        if (there == null) {
            selectedColumns.put(cval, cval);
        }
        else {
            selectedColumns.remove(cval);
        }
        reindex();
    }

    public ImageInfo defaultImage(String cval) throws Exception {
        return defImage.get(cval);
    }

    /**
     * temporarily needed for conversion.
     */
    public Vector<Vector<ImageInfo>> getEntireGrid() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return grid;
    }

    /**
     * temporarily needed for conversion.
     */
    public Vector<ImageInfo> getRow(int value) throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        int rowNum = getRowNumberForValue(value);
        if (rowNum < 0) {
            throw new JSONException("Was not able to find a row for value = {0}", value);
        }
        if (rowNum >= grid.size()) {
            throw new JSONException("Internal consistency error, got row '{0}' for value '{1}' but grid has only '{2}' rows",
                    rowNum, value, grid.size());
        }
        return grid.elementAt(rowNum);
    }

    public int getRowNumberForValue(int photoValue) throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        int last = totalRowMap.size();
        for (int i = 0; i < last; i++) {
            Integer iVal = totalRowMap.elementAt(i);
            if (iVal.intValue() >= photoValue) {
                return i;
            }
        }
        return -1;
    }

    private void flushCache() {
        rawData.clear();
        grid.clear();
        totalPerRow.clear();
        totalPerCol.clear();
        selectedPerRow.clear();
        totalRowMap.clear();
        selectedRowMap.clear();
        needsRecalc = true;
    }

    private void processQuery() throws Exception {
        flushCache();
        if (query.length() == 0) {
            // nothing to process, so just ignore this
            return;
        }
        rawData.addAll(ImageInfo.imageQuery(query));
        ImageInfo.sortImages(rawData, "num");

        Vector<ImageInfo> rowVec = null;
        int rowValue = -99999;
        for (ImageInfo ii : rawData) {
            int thisValue = ii.value;
            if (rowValue != thisValue) {
                rowVec = new Vector<ImageInfo>();
                grid.add(rowVec);
                rowValue = thisValue;
            }
            rowVec.add(ii);
        }
        reindex();
        needsRecalc = false;
    }

    public void reindex() throws Exception {
        totalPerRow.clear();
        totalPerCol.clear();
        selectedPerRow.clear();
        totalRowMap.clear();
        selectedRowMap.clear();

        for (Vector<ImageInfo> rowVec : grid) {
            for (ImageInfo ii : rowVec) {
                int thisValue = ii.value;
                String colVal = ii.getPatternSymbol();
                boolean isMarked = (selectedColumns.get(colVal) != null);
                totalPerRow.increment(thisValue);
                totalPerCol.increment(colVal);
                if (isMarked) {
                    selectedPerRow.increment(thisValue);
                }
                ImageInfo def = defImage.get(colVal);
                if (def == null || ii.value == 0 || (def.value < 0 && ii.value > def.value)) {
                    defImage.put(colVal, ii);
                }
            }
        }
        totalRowMap = totalPerRow.getSortedKeys();
        Collections.sort(totalRowMap);
        selectedRowMap = selectedPerRow.getSortedKeys();
        Collections.sort(selectedRowMap);

        // now check that all selected columns are valid in this data set
        Vector<String> removable = new Vector<String>();
        for (String testCol : selectedColumns.keySet()) {
            int num = numberInColumn(testCol);
            if (num == 0) {
                removable.add(testCol);
            }
        }
        for (String testCol : removable) {
            selectedColumns.remove(testCol);
        }
    }
    
    public JSONObject getJSON() throws Exception {
        JSONObject total = new JSONObject();
        JSONObject gridjo = new JSONObject();
        Set<String> valueSet = new HashSet<String>();
        Set<String> colSet = new HashSet<String>();
        
        for (Vector<ImageInfo> rowVec : grid) {
            for (ImageInfo ii : rowVec) {
                String thisValue = "??";
                if (ii.value>=0) {
                    thisValue = Integer.toString(1000+ii.value).substring(1);
                }
                else {
                    thisValue = Integer.toString(ii.value);
                }
                valueSet.add(thisValue);
                String thisCol = ii.getPatternSymbol();
                colSet.add(thisCol);
                
                if (!gridjo.has(thisCol)) {
                    gridjo.put(thisCol, new JSONObject());
                }
                
                JSONObject colObj = gridjo.getJSONObject(thisCol);
                colObj.put(thisValue, ii.getJSON());
            }
        }
        total.put("grid",  gridjo);

        JSONArray valuesjo = new JSONArray();
        for (String value : valueSet) {
            valuesjo.put(value);
        }
        total.put("rows",  valuesjo);

        JSONArray colsjo = new JSONArray();
        JSONObject defs = new JSONObject();
        for (String col : colSet) {
            colsjo.put(col);
            ImageInfo defImg = this.defaultImage(col);
            defs.put(col, defImg.getJSON());
        }
        total.put("cols",  colsjo);
        total.put("defs",  defs);
        
        
        return total;
    }

}
