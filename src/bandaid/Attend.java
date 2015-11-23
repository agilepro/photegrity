package bandaid;

import java.io.Writer;

public class Attend {
	public String person;
	public int status;
	public String comment;

	public Attend(String email, int stat, String comm) throws Exception {
		if (email.indexOf(':') >= 0) {
			throw new Exception("The email address is not allowed to have a colon in it");
		}
		if (comm.indexOf(':') >= 0) {
			throw new Exception("The comment is not allowed to have a colon in it");
		}
		if (comm.indexOf('\n') >= 0) {
			throw new Exception("The comment is not allowed to have a newline in it");
		}
		person = email;
		status = stat;
		comment = comm;
	}

	public static Attend parseAttendLine(String line) throws Exception {
		// pattern is a:name:status:comment
		int startPos = 2;
		int colonPos = line.indexOf(':', startPos);
		if (colonPos < 2) {
			throw new Exception("could not find a second colon in the attendance line");
		}
		String person = line.substring(startPos, colonPos);
		startPos = colonPos + 1;
		colonPos = line.indexOf(':', startPos);
		if (colonPos < startPos) {
			throw new Exception("could not find a third colon in the attendance line");
		}
		int status = Integer.parseInt(line.substring(startPos, colonPos));
		startPos = colonPos + 1;
		String comment = line.substring(startPos);
		return new Attend(person, status, comment);
	}

	public void writeLine(Writer out) throws Exception {
		out.write("a:");
		out.write(person);
		out.write(":");
		out.write(Integer.toString(status));
		out.write(":");
		writeStripNewlines(out, comment);
		out.write("\n");
	}

	public static void writeStripNewlines(Writer out, String str) throws Exception {
		int startPos = 0;
		int newLinePos = str.indexOf('\n');
		while (newLinePos >= startPos) {
			out.write(str.substring(startPos, newLinePos));
			out.write(" ");
			startPos = newLinePos + 1;
			newLinePos = str.indexOf('\n', startPos);
		}
		out.write(str.substring(startPos));
	}

	public String statusCode() {
		if (status == 1) {
			return "yes";
		}
		if (status == 2) {
			return "no";
		}
		if (status == 3) {
			return "maybe";
		}
		return "";
	}

	// Kind of a silly routine... outputs "checked" if the passed in status
	// value
	// matches the internal value, otherwise it returns a null string.
	// very handy for radio buttons
	public String radioCheck(int statCase) {
		if (statCase == status) {
			return "checked";
		}
		return "";
	}
}