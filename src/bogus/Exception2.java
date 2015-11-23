package bogus;

public class Exception2 extends Exception {
	private static final long serialVersionUID = 1L;

	// it seems that the base class of Exception insists on
	// adding the class name in front of this string, and it
	// adds nothing to the understanding of the user to put
	// 'Bogus.Exception2' at the front. In order to disable
	// this, keep a pointer to the string originally supplied
	// and user that in the message below.
	String theRealMessage;

	public Exception2(String s) {
		super(s);
		theRealMessage = s;
	}

	public Exception2(String s, Throwable th) {
		super(s, th);
		theRealMessage = s;
	}

	public String getMessage() {
		StringBuffer sb = new StringBuffer(theRealMessage);
		Throwable cause = getCause();

		if (cause != null) {
			String s = cause.getMessage();
			sb.append(" because: ");
			if (s == null) {
				s = cause.toString();
			}
			else if (s.length() < 10) {
				sb.append(" - ");
				sb.append(cause.toString());
			}
			sb.append(s);
		}
		return sb.toString();
	}

}
