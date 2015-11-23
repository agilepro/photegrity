package bandaid;

import java.io.Writer;

public class PhotoInfo {

	public String fileName;
	public String title;
	public String description;

	public PhotoInfo(String newName) {
		fileName = newName;
	}

	public void writeRecord(Writer out) throws Exception {
		out.write(fileName);
		out.write("\t");
		if (title != null) {
			out.write(title);
		}
		out.write("\t");
		out.write(convertToLiteral(description));
		out.write("\n");
	}

	public void parseRecord(String in) throws Exception {
		int tabPos = in.indexOf('\t');
		if (tabPos < 0) {
			throw new Exception("PhotoInfo record (line) does not have any tabs in it.");
		}
		fileName = in.substring(0, tabPos);
		int startPos = tabPos + 1;
		tabPos = in.indexOf('\t', startPos);
		title = in.substring(startPos, tabPos);
		startPos = tabPos + 1;
		description = convertFromLiteral(in.substring(startPos));
	}

	static public String convertToLiteral(String in) throws Exception {
		if (in == null) {
			return "";
		}
		StringBuffer res = new StringBuffer();

		for (int i = 0; i < in.length(); i++) {
			char ch = in.charAt(i);

			if (ch == '\n') {
				res.append("\\n");
			}
			else if (ch == '\t') {
				res.append("\\t");
			}
			else if (ch == '\\') {
				res.append("\\\\");
			}
			else if (ch == '\r') {
				res.append("\\r");
			}
			else {
				res.append(ch);
			}
		}

		return res.toString();
	}

	static public String convertFromLiteral(String in) throws Exception {
		if (in == null) {
			return "";
		}
		StringBuffer res = new StringBuffer();

		for (int i = 0; i < in.length(); i++) {
			char ch = in.charAt(i);

			if (ch != '\\') {
				res.append(ch);
				continue;
			}
			i++;
			if (i >= in.length()) {
				throw new Exception(
						"Encoding error, found a backslash as the last character of a encoded field, and that is never allowed.");
			}
			ch = in.charAt(i);
			if (ch == 't') {
				res.append("\t");
			}
			else if (ch == 'n') {
				res.append("\n");
			}
			else {
				res.append(ch);
			}
		}

		return res.toString();
	}
}