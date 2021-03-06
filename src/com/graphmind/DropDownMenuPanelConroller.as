package com.graphmind {
  
  import flash.filters.DropShadowFilter;
  
  import mx.containers.Canvas;
  import mx.containers.VBox;
  import mx.core.ScrollPolicy;
  import mx.core.UIComponent;
  
  public class DropDownMenuPanelConroller extends Canvas {
    
    public var menuIcon:Class;
    
    public var menuTooltip:String;

    public var panel:VBox = new VBox();
    
    public var closeTimeout:uint;
    
    
    public function DropDownMenuPanelConroller(iconSource:Class, tooltip:String) {
      super();

      this.menuIcon = iconSource;
      this.menuTooltip = tooltip;
      
      addChild(panel);
      panel.setStyle('backgroundColor', '0xDDDDDD');
      panel.setStyle('paddingTop', '12');
      panel.setStyle('paddingBottom', '12');
      panel.setStyle('paddingRight', '6');
      panel.setStyle('paddingLeft', '6');
      panel.filters = [new DropShadowFilter(1.0, 45.0, 0x888888, 1.0, 1.0, 1.0)];
      panel.horizontalScrollPolicy = ScrollPolicy.OFF;
      panel.verticalScrollPolicy = ScrollPolicy.OFF;
    }
    
    
    public function addFormItem(item:UIComponent):void {
      panel.addChild(item);
    }
    
  }
  
}
