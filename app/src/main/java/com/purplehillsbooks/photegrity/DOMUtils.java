/********************************************************************************
 *                                                                              *
 *  COPYRIGHT (C) 1997-2002 FUJITSU SOFTWARE CORPORATION.  ALL RIGHTS RESERVED. *
 *                                                                              *
 ********************************************************************************/
package com.purplehillsbooks.photegrity;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.StringReader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Vector;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.ErrorHandler;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import com.purplehillsbooks.json.JSONException;

/**
 * This class offers a number of helper functions for dealing with XML DOMS By
 * centralizing all XML specific functions here, we can maximize reuse.
 * 
 * @publish internal
 */
public class DOMUtils {

	/**
	 * Enforce the fact that this object has only static methods by having a
	 * private constructor. No reason to ever construct one of these
	 */
	private DOMUtils() {
	}

	/**
	 * @returns the text value of nodes with the specified name
	 * @param contextNode
	 * @param nodeName
	 * @param trim
	 */
	public static String[] textValuesOfAll(Node contextNode, String nodeName, boolean trim)
			throws Exception {
		NodeList nodes = findNodes(contextNode, nodeName);
		String[] retval = new String[nodes.getLength()];
		for (int i = 0; i < nodes.getLength(); i++) {
			retval[i] = textValueOf(nodes.item(i), trim);
		}
		return retval;
	}

	/**
	 * @returns the text value of a single node
	 * @param contextNode
	 * @param xpathExpr
	 *            will be used as axis::xpathExpr
	 * @param axis
	 * @param quiet
	 *            if true, does not throw exception if not found
	 * @param trim
	 */
	public static String textValueOf(Node contextNode, String nodeName, boolean trim) {
		Node node = getFirstNodeByTagName(contextNode, nodeName);
		if (node == null) {
			return null;
		}
		return textValueOf(node, trim);
	}

	/**
	 * Returns the text of all the chidren of a node as a single string
	 * 
	 * @param node
	 *            is the parent of the text
	 * @param nodeName
	 */
	public static String textValueOf(Node node, boolean trim) {
		// unfold the loop. 99.9% of the time, the XML will have a
		// single text node. Memory is much more efficiently handled
		// if the string from that text node is used directly, instead
		// of being copied into the string buffer. Unfold the loop,
		// and if there is a single child node, simply return that
		// value.
		Node child = skipToNextTextNode(node.getFirstChild());
		if (child == null) {
			return "";
		}
		Node nextChild = skipToNextTextNode(child.getNextSibling());
		if (nextChild == null) {
			if (trim) {
				return child.getNodeValue().trim();
			}
			else {
				return child.getNodeValue();
			}
		}

		// we have more than one, so make a string buffer to
		// concatenate them together.
		StringBuffer text = new StringBuffer();
		if (trim) {
			text.append(child.getNodeValue().trim());
		}
		else {
			text.append(child.getNodeValue());
		}
		child = nextChild;
		while (child != null) {
			if (trim) {
				text.append(child.getNodeValue().trim());
			}
			else {
				text.append(child.getNodeValue());
			}
			// text.append("~"); //debug
			child = skipToNextTextNode(child.getNextSibling());
		}
		return text.toString();
	}

	// if text node passed in, then that is returned.
	// if not, skips nodes that are not text nodes.
	// returns null when gets to the last sibling.
	private static Node skipToNextTextNode(Node child) {
		if (child == null) {
			return null;
		}
		while (child.getNodeType() != Node.CDATA_SECTION_NODE
				&& child.getNodeType() != Node.TEXT_NODE) {
			child = child.getNextSibling();
			if (child == null) {
				return null;
			}
		}
		return child;
	}

	/**
	 * Returns the first child (direct descendant) with the specified name
	 * Returns null if no child is found with that name. Should be called
	 * 'findChildByName'
	 * 
	 * @param contextNode
	 * @param nodeName
	 */
	public static Node getFirstNodeByTagName(Node contextNode, String nodeName) {
		// Use DOM traversaL
		Node child = contextNode.getFirstChild();
		while (child != null) {
			if (child.getNodeName().equals(nodeName)) {
				return child;
			}
			child = child.getNextSibling();
		}
		return null;
	}

	/**
	 * Searches a Node for children matching a particular Local Name
	 * 
	 * @param contextNode
	 *            - the Node to start searching from
	 * @param Local
	 *            Name - the LOCAL NAME of the child node to search for
	 *            (assuming of course that the DOM Document supports namespaces.
	 *            If not, this will search for a full name matching this string.
	 * @param recursively
	 *            - If true - this will recurse downward in the Node tree. If
	 *            false, then this will only search DIRECT CHILD NODES of the
	 *            contextNode.
	 */
	public static NodeList findNodes(Node contextNode, String expr, boolean recursively)
			throws Exception {
		if (contextNode == null) {
			// recover gracefully
			return new NodeListImpl();
		}
		try {
			// Use DOM traversal on children
			NodeListImpl nodeList = new NodeListImpl();
			Node child = contextNode.getFirstChild();
			while (child != null) {
				String lclNm = child.getLocalName();
				String fullNm = child.getNodeName();
				if ((lclNm != null && lclNm.equals(expr))
						|| (fullNm != null && fullNm.equals(expr))) {
					nodeList.add(child);
				}
				if (recursively) {
					nodeList.add(findNodes(child, expr, recursively));
				}
				child = child.getNextSibling();
			}
			return nodeList;
		}
		catch (Exception e) {
			throw new JSONException("Error while searching DOM", e);
		}
	}

	/**
	 * Recursively searches a Node for children matching a particular Local Name
	 * 
	 * @param contextNode
	 * @param Local
	 *            Name
	 */
	public static NodeList findNodes(Node contextNode, String expr) throws Exception {
		return findNodes(contextNode, expr, true);
	}

	public static Node findNodeWithAttrValue(Document doc, String elementName, String attrName,
			String attrValue) throws Exception {
		NodeList elmts = doc.getElementsByTagNameNS("*", elementName);
		;
		for (int i = 0; i < elmts.getLength(); i++) {
			NamedNodeMap attrs = elmts.item(i).getAttributes();
			if (attrs != null && attrs.getLength() > 0) {
				Node attrNode = attrs.getNamedItem(attrName);
				if (attrNode != null && attrValue.equals(attrNode.getNodeValue())) {
					return elmts.item(i);
				}
			}
		}
		return null;
	}

	/**
	 * Get an ordered list of all ELEMENTs that are children of a context Node
	 * NOTE: This is DIFFERENT THAN getElementsByTagName("*") because this
	 * method does NOT traverse the full tree!!! It just gets direct children.
	 * 
	 * @param contextNode
	 *            - a Node/Element from which we want to get all the child
	 *            elements
	 * @return a List of org.w3c.dom.Element objects or an empty List if there
	 *         are no child elements
	 */

	public static List<Element> getChildElementsList(Node contextNode) {
		ArrayList<Element> list = new ArrayList<Element>();
		NodeList childNdList = contextNode.getChildNodes();
		for (int i = 0; i < childNdList.getLength(); i++) {
			org.w3c.dom.Node n = childNdList.item(i);
			if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
				continue;
			}
			list.add((Element) n);
		}
		return list;
	}

	/**
	 * Silly method. As part of porting this from the old XML parser to DOM, use
	 * this simple method to get child Elements. The old parser has a method for
	 * getting an Enumeration. That was used in hundreds of places. This simple
	 * method is an easy replacement for that.
	 * 
	 * @param from
	 *            - a Node/Element from which we want to get all the child
	 *            elements
	 * @return an Enumeration of org.w3c.dom.Element objects or an empty
	 *         Enumeration if there are no child elements
	 */

	public static Enumeration<Element> getChildElements(Element from) {
		Vector<Element> list = new Vector<Element>();
		NodeList childNdList = from.getChildNodes();
		for (int i = 0; i < childNdList.getLength(); i++) {
			org.w3c.dom.Node n = childNdList.item(i);
			if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
				continue;
			}
			list.add((Element) n);
		}
		return list.elements();
	}

	public static Element getChildElement(Element parent, String name) {
		NodeList childNdList = parent.getChildNodes();
		for (int i = 0; i < childNdList.getLength(); i++) {
			org.w3c.dom.Node n = childNdList.item(i);
			if (n.getNodeType() != org.w3c.dom.Node.ELEMENT_NODE) {
				continue;
			}
			if (name.equals(n.getLocalName())) {
				return (Element) n;
			}
		}
		return null;
	}

	/**
	 * This method creates a new Document Object. Pass in the name of the root
	 * node, since you ALWAYS need a root node, and attaching this to the
	 * document is not like other children. Retrieve the root element with the
	 * standard getDocumentElement.
	 * 
	 * @return
	 * @throws Exception
	 */
	public static Document createDocument(String rootNodeName) throws Exception {
		DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
		dfactory.setNamespaceAware(true);
		DocumentBuilder bldr = dfactory.newDocumentBuilder();
		Document doc = bldr.newDocument();
		Element rootEle = doc.createElement(rootNodeName);
		doc.appendChild(rootEle);
		return doc;
	}

	/**
	 * This method is used to create a Child Text element.
	 * 
	 * @param doc
	 *            document on which the Text Element has to be created.
	 * @param parent
	 *            Parent Element.
	 * @param name
	 *            Tag name of the Text Element.
	 * @param textValue
	 *            tag value of the Text Element.
	 * @return Element.
	 */
	public static Element createChildElement(Document doc, Element parent, String name,
			String textValue) {
		// if a null is passed in, then do not create the child element
		// at all. Then when reading, if the element does not exist,
		// the value will be null. This is standard behaviod for
		// optional element.
		if (textValue == null) {
			return null;
		}
		Element newElem = doc.createElement(name);
		newElem.appendChild(doc.createTextNode(textValue));
		parent.appendChild(newElem);
		return newElem;
	}

	/**
	 * This method is used to create a Child Text node directly after the last
	 * child of an existing element. Needed when you have tags and text
	 * interspursed.
	 * 
	 * @param doc
	 *            document on which the Text has to be created.
	 * @param parent
	 *            Parent Element.
	 * @param textValue
	 *            tag value of the Text.
	 * @return Element.
	 */
	public static void addChildText(Document doc, Element parent, String textValue) {
		parent.appendChild(doc.createTextNode(textValue));
	}

	/**
	 * This method is used to create a Child element.
	 * 
	 * @param doc
	 *            document on which the Child Element has to be created.
	 * @param parent
	 *            Parent Element.
	 * @param name
	 *            Tag name of the Child Element.
	 * @return Element.
	 */
	public static Element createChildElement(Document doc, Element parent, String name) {
		Element newElem = doc.createElement(name);
		parent.appendChild(newElem);
		return newElem;
	}

	/**
	 * This method is used to create an element with Attributes.
	 * 
	 * @param doc
	 *            document on which the Child Element has to be created.
	 * @param parent
	 *            Parent Element.
	 * @param name
	 *            Tag Name of the Element
	 * @param attributeNames
	 *            List of Attribute names.
	 * @param attributeValues
	 *            List of Attribute values.
	 * @return Element
	 */
	public static Element createChildElement(Document doc, Element parent, String name,
			String textValue, String[] attributeNames, String[] attributeValues) {
		Element newElem = doc.createElement(name);

		if (textValue != null) {
			newElem.appendChild(doc.createTextNode(textValue));
		}

		for (int i = 0; i < attributeNames.length; i++) {
			newElem.setAttribute(attributeNames[i], attributeValues[i]);
		}

		parent.appendChild(newElem);
		return newElem;
	}

	/**
	 * This method is used to Serialize the DOM Document Object into a String.
	 * This is the preferred way to convert an XML dom tree to a String, but
	 * PLEASE try not to use this. Creating XML copies as strings in memory is a
	 * bad practice. Streaming them directly to a file, or to a socket, is
	 * better. But, if you need to have a String, use this one.
	 * 
	 * @param doc
	 *            Document Object.
	 * @return XML String.
	 * @throws Exception
	 */
	public static String convertDomToString(Document doc) throws Exception {
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DOMSource docSource = new DOMSource(doc);
		Transformer transformer = getXmlTransformer();
		transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
		transformer.setOutputProperty(OutputKeys.METHOD, "xml");
		transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
		transformer.transform(docSource, new StreamResult(new OutputStreamWriter(baos, "UTF-8")));

		return baos.toString("UTF-8");
	}

	/**
	 * This method is used to De-Serialize the DOM Document Object from a
	 * String.
	 * 
	 * @param xmlString
	 *            The XML String.
	 * @param validate
	 * @param isNamespaceAware
	 * @return Document of the DOM.
	 * @throws Exception
	 */
	public static Document convertInputStreamToDocument(InputStream is, boolean validate,
			boolean isNamespaceAware) throws Exception {
		DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
		dfactory.setNamespaceAware(isNamespaceAware);
		dfactory.setValidating(validate);
		dfactory.setIgnoringElementContentWhitespace(true);
		DocumentBuilder bldr = dfactory.newDocumentBuilder();
		bldr.setErrorHandler(new ErrorHandler() {
			public void warning(SAXParseException exception) throws SAXException {
				// ignore warnings
			}

			public void error(SAXParseException exception) throws SAXException {
				// ignore parse validation errors
			}

			public void fatalError(SAXParseException exception) throws SAXException {
				throw exception;
			}
		});
		Document doc = bldr.parse(new InputSource(is));
		return doc;
	}

	/**
	 * This method is used to De-Serialize the DOM Document Object from a
	 * String.
	 * 
	 * @param xmlString
	 *            The XML String.
	 * @param validate
	 * @param isNamespaceAware
	 * @return Document of the DOM.
	 * @throws Exception
	 */
	public static Document convertStringToDocument(String xmlString, boolean validate,
			boolean isNamespaceAware) throws Exception {
		DocumentBuilderFactory dfactory = DocumentBuilderFactory.newInstance();
		dfactory.setNamespaceAware(isNamespaceAware);
		dfactory.setValidating(validate);
		dfactory.setIgnoringElementContentWhitespace(true);
		DocumentBuilder bldr = dfactory.newDocumentBuilder();
		bldr.setErrorHandler(new ErrorHandler() {
			public void warning(SAXParseException exception) throws SAXException {
				// ignore warnings
			}

			public void error(SAXParseException exception) throws SAXException {
				// ignore parse validation errors
			}

			public void fatalError(SAXParseException exception) throws SAXException {
				throw exception;
			}
		});
		Document doc = bldr.parse(new InputSource(new StringReader(xmlString)));
		return doc;
	}

	/**
	 * This method is used to De-Serialize the DOM Document Object from a
	 * String.
	 * 
	 * @param xmlString
	 *            The XML String.
	 * @param validate
	 * @param isNamespaceAware
	 * @return Root element of the DOM.
	 * @throws Exception
	 */
	public static Element convertStringToDom(String xmlString, boolean validate,
			boolean isNamespaceAware) throws Exception {
		return convertStringToDocument(xmlString, validate, isNamespaceAware).getDocumentElement();
	}

	/**
	 * This method is used to De-Serialize the DOM Document Object from a
	 * String.
	 * 
	 * @param xmlString
	 *            The XML String.
	 * @return Root element of the DOM.
	 * @throws Exception
	 */
	public static Element convertStringToDom(String xmlString) throws Exception {
		return convertStringToDom(xmlString, true, true);
	}

	/**
	 * This method is used to De-Serialize the DOM Document Object from a
	 * String.
	 * 
	 * @param xmlString
	 *            The XML String.
	 * @return Document element of the DOM.
	 * @throws Exception
	 */
	public static Document convertStringToDocument(String xmlString) throws Exception {
		return convertStringToDocument(xmlString, true, true);
	}

	public static void writeDom(Document doc, Writer w) throws Exception {
		DOMSource docSource = new DOMSource(doc);
		Transformer transformer = getXmlTransformer();
		transformer.transform(docSource, new StreamResult(w));
	}

	public static void writeDom(Document doc, OutputStream out) throws Exception {
		DOMSource docSource = new DOMSource(doc);
		Transformer transformer = getXmlTransformer();
		transformer.transform(docSource, new StreamResult(out));
	}

	public static Document parseXMLInputStream(InputStream str) throws Exception {
		throw new java.lang.UnsupportedOperationException(
				"parseXMLInputStream is not implemented yet");
	}

	public static Document parseXMLReader(Reader str) throws Exception {
		throw new java.lang.UnsupportedOperationException("parseXMLReader is not implemented yet");
	}

	private static Transformer getXmlTransformer() throws Exception {
		/*
		 * CDATA_SECTION_ELEMENTS | cdata-section-elements = expanded names.
		 * DOCTYPE_PUBLIC | doctype-public = string. DOCTYPE_SYSTEM |
		 * doctype-system = string. ENCODING | encoding = string. INDENT |
		 * indent = "yes" | "no". MEDIA_TYPE | media-type = string. METHOD |
		 * method = "xml" | "html" | "text" | expanded name.
		 * OMIT_XML_DECLARATION | omit-xml-declaration = "yes" | "no".
		 * STANDALONE | standalone = "yes" | "no". VERSION | version = nmtoken.
		 */

		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer();
		transformer.setOutputProperty(OutputKeys.METHOD, "xml");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
		transformer.setOutputProperty(OutputKeys.INDENT, "yes");
		try {
			transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
		}
		catch (IllegalArgumentException e) {
			// If the property is not supported, and is not qualified with a
			// namespace then
			// it throws IllegalArgumentException. we do not have to re-throw
			// this exception.
		}
		return transformer;
	}

	/**************************************************************************
	 * Title: A trivial Vector based NodeList implementation Description:
	 * 
	 * @version 1.0
	 */
	private static class NodeListImpl implements NodeList {
		private ArrayList<Node> nodeVector = null;

		public NodeListImpl() {
			nodeVector = new ArrayList<Node>();
		}

		public Node item(int index) {
			return nodeVector.get(index);
		}

		public void add(NodeList appendList) {
			for (int i = 0; i < appendList.getLength(); i++) {
				nodeVector.add(appendList.item(i));
			}
		}

		public int getLength() {
			return nodeVector.size();
		}

		public void add(Node node) {
			nodeVector.add(node);
		}
	}
}
