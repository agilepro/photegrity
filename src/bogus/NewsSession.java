package bogus;

import java.io.Reader;

import org.apache.commons.net.nntp.ArticleInfo;
import org.apache.commons.net.nntp.NNTPClient;

/**
 * represents a session with a news server
 */

public class NewsSession {
	// available ... just in case
	public NNTPClient client;

	private String currentGroup;
	private String server;
	private String user;
	private String pass;
	private boolean isConnected = false;

	private static NewsSession theSingletonNewsSession;

	private NewsSession(String serverName, String userName, String password) throws Exception {
		server = serverName;
		user = userName;
		pass = password;
		currentGroup = "";
	}

	public static NewsSession getNewsSession() throws Exception {
		if (theSingletonNewsSession == null) {
			theSingletonNewsSession = new NewsSession("news.giganews.com", "gn510170", "p1ngs10t");
		}
		return theSingletonNewsSession;
	}

	public boolean isConnected() {
		return isConnected;
	}

	public synchronized void connect() throws Exception {
		if (!NewsGroup.connect) {
			//not in connected mode, so don't connect
			return;
		}
		currentGroup = "";
		client = new NNTPClient();
		try {
		    client.connect(server);
		}
		catch (Exception e) {
		    throw new Exception("Attempt to connect to server: "+server, e);
		}
		if (!client.authenticate(user, pass)) {
			throw new Exception("Unable to authenticate the new named '" + user
					+ "' on the server '" + server + "'.  Do you have the correct password?");
		}
		isConnected = true;
	}

	public synchronized void disconnect() throws Exception {
		if (client != null && client.isConnected()) {
			client.disconnect();
		}
		isConnected = false;
		client = null;
		currentGroup = "";
	}

	/**
	 * sets the group to the name only if not currently set to that group. If
	 * already set this returns fast.
	 */
	public synchronized void internalSetGroup(String groupName) throws Exception {
		if (!isConnected) {
			throw new Exception(
					"internalSelectArticle was called but the session is not connected!");
		}
		if (groupName.equals(currentGroup)) {
			return; // already set, silently ignore
		}
		if (!client.selectNewsgroup(groupName)) {
			throw new Exception("Unable to set the news session to a news group named '"
					+ groupName + "'.");
		}
		currentGroup = groupName;
	}

	/**
	 * set the client to point to a particular article
	 */
	boolean internalSelectArticle(long articleNo, ArticleInfo ptr) throws Exception {
		if (!isConnected) {
			throw new Exception(
					"internalSelectArticle was called but the session is not connected!");
		}
		return true;
	}

	public synchronized Reader getArticleHeader(long articleNo) throws Exception {
		if (!isConnected) {
			throw new Exception("getArticleHeader was called but the session is not connected!");
		}
		Reader msgReader = client.retrieveArticleHeader(articleNo);
		if (msgReader == null) {
			throw new Exception(
					"NNTPClient.retrieveArticleHeader returned a null value for article "
							+ articleNo);
		}
		return msgReader;
	}

	public synchronized Reader getArticleBody(long articleNo) throws Exception {
		if (!isConnected) {
			throw new Exception("getArticleBody was called but the session is not connected!");
		}
		Reader msgReader = client.retrieveArticle(articleNo);
		if (msgReader == null) {
			throw new Exception("NNTPClient.retrieveArticle returned a null value for article "
					+ articleNo);
		}
		return msgReader;
	}
}
