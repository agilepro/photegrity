package bogus;

import bogus.DOMUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * This is a definition of a column. This is an element of a schema, so a
 * collection of WebFields is a schema.
 */
public class WebColumn {
	// Here are the basic data types
	public static final int SIMPLE_STRING = 1;
	public static final int BLOCK_TEXT = 2;
	public static final int HYPERLINK = 3;

	public static String[] typeNames = { "Error", "String", "Block", "Link" };

	public String colName;
	public String displayName;
	public int dataType;
	public int width = 50;
	public int height = 8;
	public boolean isKey;
	public String linkTable;
	public String linkField;

	public WebColumn(String newName, String newDisp, int newType, boolean newKey) {
		// not possible to create a column with an unclean name.
		// this might be a problem if the code creating the column
		// is not expecting the name to change.
		// Might be better to throw an exception
		colName = cleanColumnName(newName);

		displayName = newDisp;
		dataType = newType;
		isKey = newKey;
	}

	public WebColumn(WebColumn rhs) {
		colName = rhs.colName;
		displayName = rhs.displayName;
		dataType = rhs.dataType;
		isKey = rhs.isKey;
		width = rhs.width;
		height = rhs.height;
		linkTable = rhs.linkTable;
		linkField = rhs.linkField;
	}

	/**
	 * A null return means everything is OK. Non null is a message to present to
	 * the user to explain what is wrong.
	 */
	public String validateData(String data) {
		return null;
	}

	public String getColName() {
		return colName;
	}

	public void setColName(WebTable table, String newName) throws Exception {
		newName = cleanColumnName(newName);
		if (colName.equals(newName)) {
			return; // already is this
		}
		// if the names are the same except for case, then we don't need
		// to look for another field with the same name ... it will find
		// this one
		if (!colName.equalsIgnoreCase(newName)) {
			WebColumn other = table.getColumn(newName);
			if (other != null) {
				throw new Exception("Can not rename column '" + colName + "' to '" + newName
						+ "' because there already exists a column with that name!");
			}
		}
		colName = newName;
	}

	/**
	 * Column names are not allowed to have any character in them because they
	 * must serve as XML tag names. This function returns a name with all the
	 * illegal characters stripped out.
	 */
	public static String cleanColumnName(String inStr) {
		if (inStr == null) {
			// probably should throw an exception
			return "z";
		}
		StringBuffer outStr = new StringBuffer();
		for (int i = 0; i < inStr.length(); i++) {
			char ch = inStr.charAt(i);
			if (ch >= '0' && ch <= '9') {
				outStr.append(ch);
			}
			else if (ch >= 'A' && ch <= 'Z') {
				outStr.append(ch);
			}
			else if (ch >= 'a' && ch <= 'z') {
				outStr.append(ch);
			}
			else if (ch == '#') {
				outStr.append("Num");
			}
			else {
				// ignore it
			}
		}
		// needs to be anything but a zero length string
		if (outStr.length() == 0) {
			outStr.append("x");
		}
		return outStr.toString();
	}

	public String getDataTypeName(int type) {
		if (type < 0 || type >= typeNames.length) {
			type = 0;
		}
		return typeNames[type];
	}

	public void setDataTypeByString(String newType) throws Exception {
		dataType = WebColumn.SIMPLE_STRING;
		for (int i = 1; i < typeNames.length; i++) {
			if (newType.equalsIgnoreCase(typeNames[i])) {
				dataType = i;
				return;
			}
		}
		throw new Exception("Not able to find a data type '" + newType + "'.");
	}

	public static WebColumn parseXML(Element parent) throws Exception {
		String cname = DOMUtils.textValueOf(parent, "colName", true);
		String dname = DOMUtils.textValueOf(parent, "displayName", true);
		String dataTypeStr = DOMUtils.textValueOf(parent, "dataType", true);
		String keyStr = DOMUtils.textValueOf(parent, "isKey", true);
		boolean keyBool = (keyStr != null);
		WebColumn wc = new WebColumn(cname, dname, 0, keyBool);
		if (dataTypeStr != null) {
			wc.setDataTypeByString(dataTypeStr.trim());
			if (wc.dataType == 0) {
				throw new Exception("Tried to set type to '" + dataTypeStr + "' and got "
						+ wc.dataType);
			}
		}
		else {
			wc.setDataTypeByString("String");
		}
		wc.linkTable = DOMUtils.textValueOf(parent, "linkTable", true);
		wc.linkField = DOMUtils.textValueOf(parent, "linkField", true);
		return wc;
	}

	public void createXML(Document d, Element parent) {
		Element e_column = DOMUtils.createChildElement(d, parent, "Column");
		DOMUtils.createChildElement(d, e_column, "colName", colName);
		DOMUtils.createChildElement(d, e_column, "displayName", displayName);
		DOMUtils.createChildElement(d, e_column, "dataType", getDataTypeName(dataType));
		if (width != 50) {
			DOMUtils.createChildElement(d, e_column, "width", Integer.toString(width));
		}
		if (height != 8) {
			DOMUtils.createChildElement(d, e_column, "height", Integer.toString(height));
		}
		if (isKey) {
			DOMUtils.createChildElement(d, e_column, "isKey", "yes");
		}
		DOMUtils.createChildElement(d, e_column, "linkTable", linkTable);
		DOMUtils.createChildElement(d, e_column, "linkField", linkField);
	}

}
