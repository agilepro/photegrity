package com.purplehillsbooks.photegrity;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

public class GridData {

    public String query = "";

    private Vector<ImageInfo> rawData = new Vector<ImageInfo>();
    private Vector<Vector<JSONObject>> grid = new Vector<Vector<JSONObject>>();
    private Hashtable<String, String> selectedColumns = new Hashtable<String, String>();

    /*
     * Retains the default image info for a particular column name
     */
    private Hashtable<String, JSONObject> defImage = new Hashtable<String, JSONObject>();

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
    
    public void clearQuery() throws Exception {
        setQuery("");
    }

    public void setQuery(String newQuery) throws Exception {
        if (!newQuery.equals(query)) {
            query = newQuery;
            flushCache();
            needsRecalc = true;
            rangeTop = -999;
            rangeBottom = 999;
            totalPerRow = new NumericCounter();
            totalPerCol = new HashCounter();
            selectedPerRow = new NumericCounter();
            totalRowMap = new Vector<Integer>();
            selectedRowMap = new Vector<Integer>();
            rawData = new Vector<ImageInfo>();
            grid = new Vector<Vector<JSONObject>>();
            selectedColumns = new Hashtable<String, String>();
            singleRow = true;
        }
    }

    public String getQuery() throws Exception {
        return query;
    }

    public List<String> getColumnMap() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return totalPerCol.getSortedKeys(selectedColumns);
    }

    public List<String> getColumnMapWithoutSelectionPrioritization() throws Exception {
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

    public Hashtable<String, String> getSelectedColumns() throws Exception {
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
        return ImageInfo.genFromJSON(defImage.get(cval));
    }
    public JSONObject defaultImage2(String cval) throws Exception {
        return defImage.get(cval);
    }

    /**
     * temporarily needed for conversion.
     */
    public Vector<Vector<JSONObject>> getEntireGrid() throws Exception {
        if (needsRecalc) {
            processQuery();
        }
        return grid;
    }

    /**
     * temporarily needed for conversion.
     */
    public Vector<JSONObject> getRow(int value) throws Exception {
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
        MongoDB mongo = new MongoDB();
        JSONArray sets = mongo.querySets(query);
        HashMap<Integer, Vector<JSONObject>> tempRows = new HashMap<Integer, Vector<JSONObject>>();
        
        for (JSONObject setRec : sets.getJSONObjectList()) {
            //String diskMgr = setRec.getString("diskMgr");
            //String localPath = setRec.getString("localPath");
            String symbol = setRec.getString("symbol");
            
            JSONArray images = setRec.getJSONArray("images");
            for (JSONObject image : images.getJSONObjectList()) {
                image.put("symbol", symbol);
                int value = image.getInt("value");
                //String fileName = image.getString("fileName");
                //ImageInfo ii = ImageInfo.findImage2(diskMgr, localPath, fileName);
                    
                Vector<JSONObject> rowVec = tempRows.get(value);
                if (rowVec==null) {
                    rowVec = new Vector<JSONObject>();
                    tempRows.put(value, rowVec);
                }
                rowVec.add(image);
            }
        }
        for (int key : tempRows.keySet()) {
            grid.add(tempRows.get(key));
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

        for (Vector<JSONObject> rowVec : grid) {
            for (JSONObject ii : rowVec) {
                int thisValue = ii.getInt("value");
                String colVal = ii.getString("symbol");
                boolean isMarked = (selectedColumns.get(colVal) != null);
                totalPerRow.increment(thisValue);
                totalPerCol.increment(colVal);
                if (isMarked) {
                    selectedPerRow.increment(thisValue);
                }
                JSONObject def = defImage.get(colVal);
                if (def == null || thisValue == 0 || !def.has("value") || (def.getInt("value") < 0 && thisValue > def.getInt("value"))) {
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
        if (needsRecalc) {
            processQuery();
        }
        JSONObject total = new JSONObject();
        JSONObject gridjo = new JSONObject();
        Set<String> valueSet = new HashSet<String>();
        Set<String> colSet = new HashSet<String>();
        
        for (Vector<JSONObject> rowVec : grid) {
            for (JSONObject ii : rowVec) {
                int value = ii.getInt("value");
                String thisValue = "??";
                if (value>=0) {
                    thisValue = Integer.toString(1000+value).substring(1);
                }
                else {
                    thisValue = Integer.toString(value);
                }
                valueSet.add(thisValue);
                String thisCol = ii.getString("symbol");
                colSet.add(thisCol);
                
                if (!gridjo.has(thisCol)) {
                    gridjo.put(thisCol, new JSONObject());
                }
                
                JSONObject colObj = gridjo.getJSONObject(thisCol);
                colObj.put(thisValue, ii);
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
            JSONObject defImg = this.defaultImage2(col);
            defs.put(col, defImg);
        }
        total.put("cols",  colsjo);
        total.put("defs",  defs);
        
        
        return total;
    }

}
