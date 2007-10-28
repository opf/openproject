ContextMenu = Class.create();
ContextMenu.prototype = {
	initialize: function (options) {
		this.options = Object.extend({selector: '.hascontextmenu'}, options || { });
		
		Event.observe(document, 'click', function(e){
		    var t = Event.findElement(e, 'a');
		    if ((t != document) && (Element.hasClassName(t, 'disabled') || Element.hasClassName(t, 'submenu'))) {
                Event.stop(e);
		    } else {
       			$('context-menu').hide();
    			if (this.selection) {
                    this.selection.removeClassName('context-menu-selection');
    			}
			}
			
		}.bind(this));
		
		$$(this.options.selector).invoke('observe', (window.opera ? 'click' : 'contextmenu'), function(e){
			if (window.opera && !e.ctrlKey) {
				return;
			}
			this.show(e);
		}.bind(this));
		
	},
	show: function(e) {
		Event.stop(e);
		Element.hide('context-menu');
		if (this.selection) {
		 this.selection.removeClassName('context-menu-selection');
		}
		$('context-menu').style['left'] = (Event.pointerX(e) + 'px');
		$('context-menu').style['top'] = (Event.pointerY(e) + 'px');		
		Element.update('context-menu', '');

		var tr = Event.findElement(e, 'tr');
		tr.addClassName('context-menu-selection');
		this.selection = tr;
		var id = tr.id.substring(6, tr.id.length);
		/* TODO: do not hard code path */
		new Ajax.Updater({success:'context-menu'}, '../../issues/context_menu/' + id, {asynchronous:true, evalScripts:true, onComplete:function(request){Effect.Appear('context-menu', {duration: 0.20})}})		
	}
}
