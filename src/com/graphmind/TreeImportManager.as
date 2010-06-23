package com.graphmind
{
	import com.graphmind.data.NodeData;
	import com.graphmind.data.NodeType;
	import com.graphmind.display.TreeArrowLink;
	import com.graphmind.display.TreeNodeController;
	import com.graphmind.net.SiteConnection;
	import com.graphmind.util.Log;
	
	public class TreeImportManager {
		
		private static var _instance:TreeImportManager = null 
		
		public function TreeImportManager()	{}
		
		public static function getInstance():TreeImportManager {
			if (_instance == null) {
				_instance = new TreeImportManager();
			}
			
			return _instance;
		}
		
		public function importMapFromString(baseNode:TreeNodeController, stringData:String):TreeNodeController {
			var xmlData:XML = new XML(stringData);
			
			var postProcessObject:Object = new Object();
			postProcessObject.arrowLinks = new Array();
			
			var _baseNode:TreeNodeController = buildGrapMindNode(xmlData.child('node')[0], postProcessObject);
			
			// Post process arrow links
			for each (var arrowLink:TreeArrowLink in postProcessObject.arrowLinks) {
				if (!arrowLink.findTargetNode()) {
					Log.error('Import - arrow links - node not found.');
				}
			}
			
			return _baseNode;
		}
		
		public function buildGrapMindNode(nodeXML:XML, postProcessObject:Object):TreeNodeController {
			// @TODO write node checking - if those are exist
			var attributes:Object = {};
			var information:Object = {};
			for each (var attribute:XML in nodeXML.child('attribute')) {
				attributes[attribute.@NAME] = unescape(attribute.@VALUE);
			}
			
			// Load html node title, if you can
			XML.ignoreWhitespace = true;
			XML.prettyIndent = 0;
			var htmlTitle:String = '';
			if (nodeXML.child('richcontent')[0]) {
				htmlTitle = nodeXML.child('richcontent')[0].html.body.children();
				htmlTitle = htmlTitle.replace(/\n/gi, '');
			}
			// Normal title
			var rawTitle:String  = unescape(String(nodeXML.@TEXT));
			
			// Site connection
			var sc:SiteConnection = null;
			if (nodeXML.site) {
				sc = SiteConnection.createSiteConnection(
					unescape(nodeXML.site.@URL),
					unescape(nodeXML.site.@USERNAME)
				);
			}
			
			var nodeItemData:NodeData = new NodeData(
				attributes,
				nodeXML.@TYPE ? nodeXML.@TYPE : NodeType.NORMAL,
				sc || SiteConnection.createSiteConnection()
			);
			nodeItemData.created  = Number(nodeXML.@CREATED);
			nodeItemData.modified = Number(nodeXML.@MODIFIED);
			nodeItemData.title    = rawTitle.length > 0 ? rawTitle : htmlTitle;
			nodeItemData.id       = String(nodeXML.@ID);
			nodeItemData.link     = unescape(String(nodeXML.@LINK));
			var nodeItem:TreeNodeController = new TreeNodeController(nodeItemData);
			
			// ArrowLinks
			var arrowLinkXMLList:XMLList = nodeXML.elements('arrowlink'); 
			if (arrowLinkXMLList.length() > 0) {
				for each (var arrowLinkXML:Object in arrowLinkXMLList) {
					var arrowLink:TreeArrowLink = new TreeArrowLink(nodeItem, arrowLinkXML.@DESTINATION.toString());
					(postProcessObject.arrowLinks as Array).push(arrowLink);
				}
			}
			
			// Icons
			for each (var iconsXML:XML in nodeXML.elements('icon')) {
				nodeItem.addIcon(GraphMindManager.getInstance().getIconPath() + iconsXML.@BUILTIN + '.png');
			}
			nodeItem.getUI().initGraphics();
			
			
			var nodeChilds:XMLList = nodeXML.elements('node');
			for each (var childXML:XML in nodeChilds) {
				var childNode:TreeNodeController = buildGrapMindNode(childXML, postProcessObject);
				nodeItem.addChildNodeWithStageRefresh(childNode);
			}
			
			if (nodeXML.@FOLDED == 'true') {
				nodeItem.collapse();
			}
			
			if (nodeXML.elements('cloud').length() == 1) {
				nodeItem.toggleCloud();
			}
			
			return nodeItem;
		}

	}
}