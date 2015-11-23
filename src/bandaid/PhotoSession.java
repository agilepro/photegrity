package bandaid;

public class PhotoSession {

	public PhotoList selection;
	public String userName;
	public String password;
	public String thumbsize;
	public String columns;
	public int maxWidth; // requested width of full photo
	public int maxHeight; // requested height of full photo

	public PhotoList set = new PhotoList();
	public String setName = "";

	public PhotoSession(String u, String p, AppInstance a) {
		userName = u;
		password = p;
		selection = new PhotoList();
		thumbsize = "300";
		columns = "3";
		maxWidth = 600;
		maxHeight = 600;
	}

	public void loadSet(String ns) throws Exception {
		if (ns.equals(setName)) {
			return; // already loaded
		}

		set.clear();
		setName = "";
		set.appendFile(ns);
		setName = ns;
	}

}