package com.graphmind {
  
	import com.graphmind.data.DrupalViews;
	import com.graphmind.display.ConfigPanelController;
	import com.graphmind.event.EventCenter;
	import com.graphmind.event.EventCenterEvent;
	import com.graphmind.util.Log;
	import com.kitten.events.ConnectionEvent;
	import com.kitten.events.ConnectionIOErrorEvent;
	import com.kitten.events.ConnectionNetStatusEvent;
	
	import components.ApplicationSettingsComponent;
	import components.ConnectionSettingsComponent;
	
	import flash.display.StageDisplayState;
	import flash.events.MouseEvent;
	
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;
	
	import plugins.*;
	
	
	public class ApplicationController {
	  
	  /**
	  * Shared instance.
	  */
	  [Bindable]
	  public static var i:ApplicationController;
	  
		/**
		 * Logging mode is enabled or not.
		 */
		public static var LOG_MODE:Boolean = true;
		
    /**
     * Tree map view controller.
     */
    [Bindable]
    public var treeMapViewController:TreeMapViewController;
    
    /**
    * Application form elemets' controller.
    */
    [Bindable]
    public var appFormController:AppFormController;
		
		/**
		 * Indicates the access permissions.
		 */
		protected var _isEditable:Boolean = false;
		
		/**
		 * Feature array.
		 */
		public var features:Array;
		
		/**
		 * Disk image source for the save button.
		 */
	  [Embed(source="assets/images/disk.png")]
	  private var diskImage:Class;

    /**
    * Gear image source for the settings icon.
    */
    [Embed(source="assets/images/cog.png")]
    private var gearImage:Class;
    
    private var applicationSettingsPanel:ConfigPanelController;
    private var applicationSettingsComponent:ApplicationSettingsComponent;
    
    /**
    * Full screen image source.
    */
    [Embed(source="assets/images/arrow_out.png")]
    private var fullScreenImage:Class;
    
    /**
    * Connections image source.
    */
    [Embed(source="assets/images/connect.png")]
    private var connectionImage:Class;
    
    private var connectionSettingsComponent:ConnectionSettingsComponent;
    private var connectionSettingsPanel:ConfigPanelController;
    
    
		/**
		 * Constructor.
		 */
		public function ApplicationController() {
		  ApplicationController.i = this;
		  
		  // Add general ui form controller
		  appFormController = new AppFormController();
		  
		  // Set MainMenu
		  MainMenuController.init(GraphMind.i.mainMenuBar);
		  
      // Edit mode has to be false by default.
      // Editing privileges have to be arrived from the backend with the user object.
      setEditMode(false);
      
      if (Application.application.parameters.hasOwnProperty('features')) {
        FeatureController.features = Application.application.parameters['features'].toString().split(',');
      }
      
      treeMapViewController = new TreeMapViewController();
      GraphMind.i.map.addChild(this.treeMapViewController.view);
      
		  // Establish connection to the Drupal site.
      ConnectionController.mainConnection = ConnectionController.createConnection(getBaseDrupalURL());
      ConnectionController.mainConnection.isSessionAuthentication = true;
      
      ConnectionController.mainConnection.addEventListener(ConnectionEvent.CONNECTION_IS_READY, onSuccess_siteIsConnected);
      ConnectionController.mainConnection.addEventListener(ConnectionIOErrorEvent.IO_ERROR_EVENT, ConnectionController.defaultIOErrorHandler);
      ConnectionController.mainConnection.addEventListener(ConnectionNetStatusEvent.NET_STATUS_EVENT, ConnectionController.defaultNetStatusHandler);
      ConnectionController.mainConnection.connect();
      
      EventCenter.subscribe(EventCenterEvent.REQUEST_FOR_FREEMIND_XML, onAppFormRequestForFreemindXml);
      
      MainMenuController.createIconMenuItem(diskImage, 'Save', onClick_saveMenuItem);
      MainMenuController.createIconMenuItem(fullScreenImage, 'Toggle full screen', onClick_fullScreenIcon);
      
      applicationSettingsComponent = new ApplicationSettingsComponent();
      applicationSettingsPanel = new ConfigPanelController('Map settings');
      applicationSettingsPanel.addItem(applicationSettingsComponent);
      MainMenuController.createIconMenuItem(gearImage, 'Settings', onClick_ApplicationSettingsMenuItem);
      applicationSettingsComponent.desktopScaleHSlider.addEventListener(SliderEvent.CHANGE, onChange_mapScaleSlider);
      applicationSettingsComponent.nodeSizeSelect.addEventListener(FlexEvent.DATA_CHANGE, onDataChange_nodeSizeSelect);
      
      connectionSettingsComponent = new ConnectionSettingsComponent();
      connectionSettingsPanel = new ConfigPanelController('Remote connections');
      connectionSettingsPanel.addItem(connectionSettingsComponent);
      MainMenuController.createIconMenuItem(connectionImage, 'Connections', onClick_ConnectionsMenuItem);
      
      NodeViewController.init();
		}
			
			
		/**
		 * Get the host Drupal site's URL
		 */
		public static function getBaseDrupalURL():String {
			return Application.application.parameters.basePath;
		}
		
		
		/**
		 * Get hosting node's NID
		 */
		public static function getHostNodeID():int {
			return Application.application.parameters.nid;
		}
		
		
		/**
		 * URL for the icons.
		 */
		public static function getIconPath():String {
			return Application.application.parameters.iconDir;
		}


		/**
		 * Site is connected already
		 */
		protected function onSuccess_siteIsConnected(event:ConnectionEvent):void {
		  Log.info("Connection to Drupal is established.");
			// Get all the available features
			ConnectionController.mainConnection.call('graphmind.getFeatures', onSuccess_featuresAreLoaded, null, getHostNodeID());
			ConnectionController.mainConnection.call('graphmind.getViews', onSuccess_viewsListsAreLoaded, null);
			ConnectionController.mainConnection.call('node.get', onSuccess_rootNodeIsLoaded, null, getHostNodeID());
		}
		
		
		/**
		 * Features are loaded.
		 * Features are disabled by default.
		 */
		protected function onSuccess_featuresAreLoaded(result:Object):void {
		  Log.info("Features are loaded: " + result.toString());
		  this.features = result as Array;
		}
		
		
		/**
		 * Base site's views are loaded already
		 */
		protected function onSuccess_viewsListsAreLoaded(result:Object):void {
		  Log.info("Views lists are loaded: " + (result as Array).length);
		  // Populate Views lists.
      for each (var data:Object in result) {
        new DrupalViews(data, ConnectionController.mainConnection);
      }
		}

  
    /**
    * Root node is loaded.
    */
    protected function onSuccess_rootNodeIsLoaded(result:Object):void {
      Log.info("Root node is loaded: " + result.nid);
      setEditMode(result.graphmindEditable == '1');
      TreeMapViewController.rootNode = ImportManager.importNodesFromDrupalResponse(result);
      
      // Call map to draw its contents.
      EventCenter.notify(EventCenterEvent.MAP_TREE_IS_COMPLETE);
      EventCenter.notify(EventCenterEvent.MAP_UPDATED);
    }

    
    /**
    * Checks if the user has access to edit the mindmap.
    * @TODO if not, it should be only a not-savable mode, not an editless mode.
    */
		public function isEditable():Boolean {
			return _isEditable;
		}
		
		
		/**
		 * Set the edit mode.
		 */
		public function setEditMode(editable:Boolean):void {
			_isEditable = editable;
			if (!_isEditable) {
				GraphMind.i.currentState = 'only_view_mode';
			} else {
				GraphMind.i.currentState = '';
			}
		}
		
		
		/**
		 * Checks is the map is connected to a site.
		 */
		public function isBaseConnectionLive():Boolean {
		  return ConnectionController.mainConnection.isConnected;
		}
		
		
		protected function onAppFormRequestForFreemindXml(event:EventCenterEvent):void {
		  var xml:String = ExportController.getFreeMindXML(TreeMapViewController.rootNode);
		  (event.data as Function)(xml);
		}


    protected function onClick_saveMenuItem(event:MouseEvent):void {
      EventCenter.notify(EventCenterEvent.REQUEST_TO_SAVE);
    }
    
    
    protected function onChange_mapScaleSlider(e:SliderEvent):void {
      EventCenter.notify(EventCenterEvent.MAP_SCALE_CHANGED, e.value);
    }
    
    
    protected function onClick_fullScreenIcon(event:MouseEvent):void {
      try {
        switch (Application.application.stage.displayState) {
          case StageDisplayState.FULL_SCREEN:
            Application.application.stage.displayState = StageDisplayState.NORMAL;
            break;
          case StageDisplayState.NORMAL:
            Application.application.stage.displayState = StageDisplayState.FULL_SCREEN;
            break;
        }
      } catch (e:Error) {
        Log.error('Toggling full screen mode is not working.');
      }
    }

  
    protected function onDataChange_nodeSizeSelect(e:FlexEvent):void {
      EventCenter.notify(EventCenterEvent.REQUEST_TO_CHANGE_NODE_SIZE, applicationSettingsComponent.nodeSizeSelect.selectedIndex);
    }
    
    
    protected function onClick_ApplicationSettingsMenuItem(e:MouseEvent):void {
      applicationSettingsPanel.show();
    }

  
    protected function onClick_ConnectionsMenuItem(e:MouseEvent):void {
      connectionSettingsPanel.show();
    }
	}

}
