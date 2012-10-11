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
	tinymce.create('tinymce.plugins.VisualChars', {
		init : function(ed, url) {
			var t = this;

			t.editor = ed;

			// Register commands
			ed.addCommand('mceVisualChars', t._toggleVisualChars, t);

			// Register buttons
			ed.addButton('visualchars', {title : 'visualchars.desc', cmd : 'mceVisualChars'});

			ed.onBeforeGetContent.add(function(ed, o) {
				if (t.state && o.format != 'raw' && !o.draft) {
					t.state = true;
					t._toggleVisualChars(false);
				}
			});
		},

		getInfo : function() {
			return {
				longname : 'Visual characters',
				author : 'Moxiecode Systems AB',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/visualchars',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		},

		// Private methods

		_toggleVisualChars : function(bookmark) {
			var t = this, ed = t.editor, nl, i, h, d = ed.getDoc(), b = ed.getBody(), nv, s = ed.selection, bo, div, bm;

			t.state = !t.state;
			ed.controlManager.setActive('visualchars', t.state);

			if (bookmark)
				bm = s.getBookmark();

			if (t.state) {
				nl = [];
				tinymce.walk(b, function(n) {
					if (n.nodeType == 3 && n.nodeValue && n.nodeValue.indexOf('\u00a0') != -1)
						nl.push(n);
				}, 'childNodes');

				for (i = 0; i < nl.length; i++) {
					nv = nl[i].nodeValue;
					nv = nv.replace(/(\u00a0)/g, '<span data-mce-bogus="1" class="mceItemHidden mceItemNbsp">$1</span>');

					div = ed.dom.create('div', null, nv);
					while (node = div.lastChild)
						ed.dom.insertAfter(node, nl[i]);

					ed.dom.remove(nl[i]);
				}
			} else {
				nl = ed.dom.select('span.mceItemNbsp', b);

				for (i = nl.length - 1; i >= 0; i--)
					ed.dom.remove(nl[i], 1);
			}

			s.moveToBookmark(bm);
		}
	});

	// Register plugin
	tinymce.PluginManager.add('visualchars', tinymce.plugins.VisualChars);
})();