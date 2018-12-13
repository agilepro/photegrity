package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONException;

/**
* This is a base class for an object which could be a wikitable row
* It is a flexivle self describing object which can be easily used
* to mae a web interface.
*/
public class WebTable
{
    private static Hashtable<String, WebTable> allTables  = new Hashtable<String, WebTable>();

    //there are many many duplicates of the same string.  This table
    //has one entry for every string value, and it prefers the one in the
    //hash table if one exists.  Keeps from holding many many
    //copies of the same string in memory.
    private Hashtable<String, String> stringCompressor = new Hashtable<String, String>();

    //This configuration setting must be set before reading a file.
    public static String dataDirectory = null;

    Vector<WebColumn> colOrder = new Vector<WebColumn>();

    Vector<WebObject> instances = new Vector<WebObject>();

    public String schemaName;

    public static WebTable getTable(String tableName)
        throws Exception
    {
        WebTable wt = allTables.get(tableName);

        if (wt!=null) {
            return wt;
        }

        //otherwise, we need to load it from disk
        File tableFile = new File(dataDirectory, tableName+".wtab");

        if (!tableFile.exists()) {
            return null;
        }

        wt = new WebTable(tableName);

        FileInputStream fis = new FileInputStream(tableFile);

        Document d = DOMUtils.convertInputStreamToDocument(fis,false,true);
        Element root = d.getDocumentElement();
        Element e_column_container = DOMUtils.getChildElement(root, "columns");
        if (e_column_container!=null) {
            Enumeration<Element> e1 = DOMUtils.getChildElements(e_column_container);
            while (e1.hasMoreElements()) {
                Element child = e1.nextElement();
                WebColumn wc = WebColumn.parseXML(child);
                if (wc.dataType==0) {
                    throw new JSONException("some how the type is not set");
                }
                wt.addColumn(wc);
            }
        }
        Element e_rows_container = DOMUtils.getChildElement(root, "rows");
        if (e_rows_container!=null) {
            Enumeration<Element> e2 = DOMUtils.getChildElements(e_rows_container);
            while (e2.hasMoreElements()) {
                Element e_row = e2.nextElement();
                WebObject wo = wt.createRow();
                wo.setAllFieldsFromXML(e_row);
            }
        }

        wt.registerTable();
        return wt;

    }

    public static Enumeration<WebTable> listTables()
    {
        return allTables.elements();
    }

    public WebTable(String newName) {
        schemaName = newName;
    }

    /**
    * Puts the table into the pool so that others
    * can see it.
    */
    public void registerTable()
    {
        allTables.put(schemaName, this);
    }

    /**
    * Removes this table object from the collection of loaded
    * table object, without saving it to disk, so that next request
    * for this table will not find the cached values,
    * and they will be reloaded from disk.  Note, that the table
    * itself is not altered, it does not load the new values
    * into this table object, so if anything is holding on to a
    * reference to this object, it will continue to see the old
    * values.  This is important since another thread might be
    * using the table at the time.  If you want to see the reverted
    * values from the file, you must throw this table away, and
    * fetch a new one which will have the values from the file.
    */
    public void deleteCachedValues()
    {
        allTables.remove(schemaName);
        stringCompressor = new Hashtable<String, String>();
    }

    public void addColumn(WebColumn newCol)
    {
        colOrder.add(newCol);
    }
    public void removeColumn(WebColumn newCol)
    {
        colOrder.remove(newCol);
    }

    /**
    * This method returns the schema for the WebObject.
    * It is a collection of WebField objects, each of which
    * describes a particular value.
    * Must be implemented by the subclass.
    */
    public Vector<WebColumn> getSchema()
    {
        return colOrder;
    }

    public WebColumn getColumn(String name)
    {
        Enumeration<WebColumn> e = colOrder.elements();
        while (e.hasMoreElements()) {
            WebColumn wc = e.nextElement();

            if (name.equalsIgnoreCase(wc.colName)) {
                return wc;
            }
        }
        return null;
    }

    // Changes a column to a new name, including updating all
    // of the objects so the data appears in the new column
    public void changeColumnName(String oldName, String newName)
        throws Exception
    {
        try {
            WebColumn wc = getColumn(oldName);
            if (wc==null) {
                throw new JSONException("There is no column named '{0}'.", oldName);
            }
            newName = WebColumn.cleanColumnName(newName);
            if (oldName.equals(newName)) {
                return;  //nothing to do
            }
            wc.setColName(this, newName);

            Enumeration<WebObject> e = instances.elements();
            while (e.hasMoreElements()) {
                WebObject wo = e.nextElement();
                wo.changeColumnName(oldName, wc);
            }
        }
        catch (Exception e) {
            throw new JSONException("Can't change column '{0}' to '{1}' in table '{2}'.", e, oldName, newName, schemaName);
        }
    }

    // Changes a column to a new name, including updating all
    // of the objects so the data appears in the new column
    public void recalculateKeys()
        throws Exception
    {
        try {
            Enumeration<WebObject> e = instances.elements();
            while (e.hasMoreElements()) {
                WebObject wo = e.nextElement();
                wo.generateKeyValue();
            }
        }
        catch (Exception e) {
            throw new JSONException("Can't regenerate key values in table '{0}'.", e, schemaName);
        }
    }

    public Enumeration<WebObject> getInstances()
    {
        return instances.elements();
    }

    public int instanceCount()
    {
        return instances.size();
    }

    public void addInstance(WebObject wo)
    {
        instances.add(wo);
    }

    public WebObject findByKey(String searchVal)
        throws Exception
    {
        Enumeration<WebObject> e = instances.elements();
        while (e.hasMoreElements()) {
            WebObject wo = e.nextElement();
            if (wo.keyEquals(searchVal)) {
                return wo;
            }
        }
        return null;
    }

    public Vector<WebObject> findMatching(String fieldName, String val)
        throws Exception
    {
        return restrictEquals(instances.elements(), fieldName, val);
    }

    public Vector<WebObject> restrictEquals(Enumeration<WebObject> source, String fieldName, String val)
        throws Exception
    {
        Vector<WebObject> res = new Vector<WebObject>();
        while (source.hasMoreElements()) {
            WebObject wo = source.nextElement();
            if (wo.fieldEquals(fieldName, val)) {
                res.add(wo);
            }
        }
        return res;
    }

    public Vector<WebObject> restrictContains(Enumeration<WebObject> source, String fieldName, String searchVal)
        throws Exception
    {
        Vector<WebObject> res = new Vector<WebObject>();
        String lowerSearch = searchVal.toLowerCase();
        while (source.hasMoreElements()) {
            WebObject wo = source.nextElement();
            String instVal = wo.getFieldValue(fieldName);
            if (instVal==null) {
                continue;
            }
            instVal = instVal.toLowerCase();
            if (instVal.indexOf(lowerSearch)>=0) {
                res.add(wo);
            }
        }
        return res;
    }


    public Vector<WebObject> sort(Enumeration<WebObject> source, String sortList)
        throws Exception
    {
        String[] sortBy = sortList.split(",");
        Vector<WebObject> res = new Vector<WebObject>();
        while (source.hasMoreElements()) {
            res.add(source.nextElement());
        }
        Comparator<WebObject> c = new OrderByFieldList(sortBy);
        Collections.sort(res, c);
        return res;
    }


    public WebObject createRow()
    {
        WebObject newObj = new WebObject(this);
        addInstance(newObj);
        return newObj;
    }

    public WebObject getEmptyObject()
    {
        //because the creation of the webo object will put iself into
        //the table, we need to remove it, because empty objects are
        //just containers that act like an object, but dont actually
        //have any values, and don't actually save anything.  You can't
        //find them any other way.  The key value is bogus.
        WebObject fakeObj = new WebObject(this);
        return fakeObj;
    }


    public String compressString(String inStr)
    {
        String otherVal = stringCompressor.get(inStr);
        if (otherVal!=null) {
            return otherVal;
        }
        stringCompressor.put(inStr, inStr);
        return inStr;
    }


    //------------------------------

    static class OrderByField implements Comparator<Object>
    {
        String sortField;

        public OrderByField(String fieldName) {
            sortField = fieldName;
        }

        public int compare(Object o1, Object o2)
        {
            String val1 = ((WebObject)o1).getFieldValue(sortField);
            String val2 = ((WebObject)o2).getFieldValue(sortField);
            if (val1==null) {
                if (val2==null) {
                    return 0;
                }
                else {
                    return -1;
                }
            }
            return val1.compareToIgnoreCase(val2);
        }
    }

    static class OrderByFieldList implements Comparator<WebObject>
    {
        String[] sortBy;

        public OrderByFieldList(String[] newSortBy) {
            sortBy = newSortBy;
        }

        public int compare(WebObject o1, WebObject o2)
        {
            for (int i=0; i<sortBy.length; i++)
            {
                String val1 = o1.getFieldValue(sortBy[i]);
                String val2 = o2.getFieldValue(sortBy[i]);
                if (val1==null) {
                    if (val2!=null) {
                        return -1;
                    }
                }
                else {
                    int comp = val1.compareToIgnoreCase(val2);
                    if (comp!=0) {
                        return comp;
                    }
                }
            }
            return 0;
        }
    }

}
