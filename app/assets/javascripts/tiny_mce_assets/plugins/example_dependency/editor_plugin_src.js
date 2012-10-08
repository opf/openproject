/**
 * editor_plugin_src.js
 *
 * Copyright 2009, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://tinymce.moxiecode.com/license
 * Contributing: http://tinymce.moxiecode.com/contributing
 */

(function() {

	tinymce.create('tinymce.plugins.ExampleDependencyPlugin', {
		/**
		 * Initializes the plugin, this will be executed after the plugin has been created.
		 * This call is done before the editor instance has finished it's initialization so use the onInit event
		 * of the editor instance to intercept that event.
		 *
		 * @param {tinymce.Editor} ed Editor instance that the plugin is initialized in.
		 * @param {string} url Absolute URL to where the plugin is located.
		 */
		init : function(ed, url) {
		},


		/**
		 * Returns information about the plugin as a name/value array.
		 * The current keys are longname, author, authorurl, infourl and version.
		 *
		 * @return {Object} Name/value array containing information about the plugin.
		 */
		getInfo : function() {
			return {
				longname : 'Example Dependency plugin',
				author : 'Some author',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/example_dependency',
				version : "1.0"
			};
		}
	});

	/**
	 * Register the plugin, specifying the list of the plugins that this plugin depends on.  They are specified in a list, with the list loaded in order.
	 * plugins in this list will be initialised when this plugin is initialized. (before the init method is called).
	 * plugins in a depends list should typically be specified using the short name).  If neccesary this can be done
	 * with an object which has the url to the plugin and the shortname.
	 */
	tinymce.PluginManager.add('example_dependency', tinymce.plugins.ExampleDependencyPlugin, ['example']);
})();
