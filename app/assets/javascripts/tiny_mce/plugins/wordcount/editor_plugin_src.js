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
	tinymce.create('tinymce.plugins.WordCount', {
		block : 0,
		id : null,
		countre : null,
		cleanre : null,

		init : function(ed, url) {
			var t = this, last = 0, VK = tinymce.VK;

			t.countre = ed.getParam('wordcount_countregex', /[\w\u2019\'-]+/g); // u2019 == &rsquo;
			t.cleanre = ed.getParam('wordcount_cleanregex', /[0-9.(),;:!?%#$?\'\"_+=\\\/-]*/g);
			t.update_rate = ed.getParam('wordcount_update_rate', 2000);
			t.update_on_delete = ed.getParam('wordcount_update_on_delete', false);
			t.id = ed.id + '-word-count';

			ed.onPostRender.add(function(ed, cm) {
				var row, id;

				// Add it to the specified id or the theme advanced path
				id = ed.getParam('wordcount_target_id');
				if (!id) {
					row = tinymce.DOM.get(ed.id + '_path_row');

					if (row)
						tinymce.DOM.add(row.parentNode, 'div', {'style': 'float: right'}, ed.getLang('wordcount.words', 'Words: ') + '<span id="' + t.id + '">0</span>');
				} else {
					tinymce.DOM.add(id, 'span', {}, '<span id="' + t.id + '">0</span>');
				}
			});

			ed.onInit.add(function(ed) {
				ed.selection.onSetContent.add(function() {
					t._count(ed);
				});

				t._count(ed);
			});

			ed.onSetContent.add(function(ed) {
				t._count(ed);
			});

			function checkKeys(key) {
				return key !== last && (key === VK.ENTER || last === VK.SPACEBAR || checkDelOrBksp(last));
			}

			function checkDelOrBksp(key) {
				return key === VK.DELETE || key === VK.BACKSPACE;
			}

			ed.onKeyUp.add(function(ed, e) {
				if (checkKeys(e.keyCode) || t.update_on_delete && checkDelOrBksp(e.keyCode)) {
					t._count(ed);
				}

				last = e.keyCode;
			});
		},

		_getCount : function(ed) {
			var tc = 0;
			var tx = ed.getContent({ format: 'raw' });

			if (tx) {
					tx = tx.replace(/\.\.\./g, ' '); // convert ellipses to spaces
					tx = tx.replace(/<.[^<>]*?>/g, ' ').replace(/&nbsp;|&#160;/gi, ' '); // remove html tags and space chars

					// deal with html entities
					tx = tx.replace(/(\w+)(&.+?;)+(\w+)/, "$1$3").replace(/&.+?;/g, ' ');
					tx = tx.replace(this.cleanre, ''); // remove numbers and punctuation

					var wordArray = tx.match(this.countre);
					if (wordArray) {
							tc = wordArray.length;
					}
			}

			return tc;
		},

		_count : function(ed) {
			var t = this;

			// Keep multiple calls from happening at the same time
			if (t.block)
				return;

			t.block = 1;

			setTimeout(function() {
				if (!ed.destroyed) {
					var tc = t._getCount(ed);
					tinymce.DOM.setHTML(t.id, tc.toString());
					setTimeout(function() {t.block = 0;}, t.update_rate);
				}
			}, 1);
		},

		getInfo: function() {
			return {
				longname : 'Word Count plugin',
				author : 'Moxiecode Systems AB',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/wordcount',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});

	tinymce.PluginManager.add('wordcount', tinymce.plugins.WordCount);
})();
