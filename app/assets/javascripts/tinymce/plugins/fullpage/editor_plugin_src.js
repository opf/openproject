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
	var each = tinymce.each, Node = tinymce.html.Node;

	tinymce.create('tinymce.plugins.FullPagePlugin', {
		init : function(ed, url) {
			var t = this;

			t.editor = ed;

			// Register commands
			ed.addCommand('mceFullPageProperties', function() {
				ed.windowManager.open({
					file : url + '/fullpage.htm',
					width : 430 + parseInt(ed.getLang('fullpage.delta_width', 0)),
					height : 495 + parseInt(ed.getLang('fullpage.delta_height', 0)),
					inline : 1
				}, {
					plugin_url : url,
					data : t._htmlToData()
				});
			});

			// Register buttons
			ed.addButton('fullpage', {title : 'fullpage.desc', cmd : 'mceFullPageProperties'});

			ed.onBeforeSetContent.add(t._setContent, t);
			ed.onGetContent.add(t._getContent, t);
		},

		getInfo : function() {
			return {
				longname : 'Fullpage',
				author : 'Moxiecode Systems AB',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/fullpage',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		},

		// Private plugin internal methods

		_htmlToData : function() {
			var headerFragment = this._parseHeader(), data = {}, nodes, elm, matches, editor = this.editor;

			function getAttr(elm, name) {
				var value = elm.attr(name);

				return value || '';
			};

			// Default some values
			data.fontface = editor.getParam("fullpage_default_fontface", "");
			data.fontsize = editor.getParam("fullpage_default_fontsize", "");

			// Parse XML PI
			elm = headerFragment.firstChild;
			if (elm.type == 7) {
				data.xml_pi = true;
				matches = /encoding="([^"]+)"/.exec(elm.value);
				if (matches)
					data.docencoding = matches[1];
			}

			// Parse doctype
			elm = headerFragment.getAll('#doctype')[0];
			if (elm)
				data.doctype = '<!DOCTYPE' + elm.value + ">"; 

			// Parse title element
			elm = headerFragment.getAll('title')[0];
			if (elm && elm.firstChild) {
				data.metatitle = elm.firstChild.value;
			}

			// Parse meta elements
			each(headerFragment.getAll('meta'), function(meta) {
				var name = meta.attr('name'), httpEquiv = meta.attr('http-equiv'), matches;

				if (name)
					data['meta' + name.toLowerCase()] = meta.attr('content');
				else if (httpEquiv == "Content-Type") {
					matches = /charset\s*=\s*(.*)\s*/gi.exec(meta.attr('content'));

					if (matches)
						data.docencoding = matches[1];
				}
			});

			// Parse html attribs
			elm = headerFragment.getAll('html')[0];
			if (elm)
				data.langcode = getAttr(elm, 'lang') || getAttr(elm, 'xml:lang');
	
			// Parse stylesheet
			elm = headerFragment.getAll('link')[0];
			if (elm && elm.attr('rel') == 'stylesheet')
				data.stylesheet = elm.attr('href');

			// Parse body parts
			elm = headerFragment.getAll('body')[0];
			if (elm) {
				data.langdir = getAttr(elm, 'dir');
				data.style = getAttr(elm, 'style');
				data.visited_color = getAttr(elm, 'vlink');
				data.link_color = getAttr(elm, 'link');
				data.active_color = getAttr(elm, 'alink');
			}

			return data;
		},

		_dataToHtml : function(data) {
			var headerFragment, headElement, html, elm, value, dom = this.editor.dom;

			function setAttr(elm, name, value) {
				elm.attr(name, value ? value : undefined);
			};

			function addHeadNode(node) {
				if (headElement.firstChild)
					headElement.insert(node, headElement.firstChild);
				else
					headElement.append(node);
			};

			headerFragment = this._parseHeader();
			headElement = headerFragment.getAll('head')[0];
			if (!headElement) {
				elm = headerFragment.getAll('html')[0];
				headElement = new Node('head', 1);

				if (elm.firstChild)
					elm.insert(headElement, elm.firstChild, true);
				else
					elm.append(headElement);
			}

			// Add/update/remove XML-PI
			elm = headerFragment.firstChild;
			if (data.xml_pi) {
				value = 'version="1.0"';

				if (data.docencoding)
					value += ' encoding="' + data.docencoding + '"';

				if (elm.type != 7) {
					elm = new Node('xml', 7);
					headerFragment.insert(elm, headerFragment.firstChild, true);
				}

				elm.value = value;
			} else if (elm && elm.type == 7)
				elm.remove();

			// Add/update/remove doctype
			elm = headerFragment.getAll('#doctype')[0];
			if (data.doctype) {
				if (!elm) {
					elm = new Node('#doctype', 10);

					if (data.xml_pi)
						headerFragment.insert(elm, headerFragment.firstChild);
					else
						addHeadNode(elm);
				}

				elm.value = data.doctype.substring(9, data.doctype.length - 1);
			} else if (elm)
				elm.remove();

			// Add/update/remove title
			elm = headerFragment.getAll('title')[0];
			if (data.metatitle) {
				if (!elm) {
					elm = new Node('title', 1);
					elm.append(new Node('#text', 3)).value = data.metatitle;
					addHeadNode(elm);
				}
			}

			// Add meta encoding
			if (data.docencoding) {
				elm = null;
				each(headerFragment.getAll('meta'), function(meta) {
					if (meta.attr('http-equiv') == 'Content-Type')
						elm = meta;
				});

				if (!elm) {
					elm = new Node('meta', 1);
					elm.attr('http-equiv', 'Content-Type');
					elm.shortEnded = true;
					addHeadNode(elm);
				}

				elm.attr('content', 'text/html; charset=' + data.docencoding);
			}

			// Add/update/remove meta
			each('keywords,description,author,copyright,robots'.split(','), function(name) {
				var nodes = headerFragment.getAll('meta'), i, meta, value = data['meta' + name];

				for (i = 0; i < nodes.length; i++) {
					meta = nodes[i];

					if (meta.attr('name') == name) {
						if (value)
							meta.attr('content', value);
						else
							meta.remove();

						return;
					}
				}

				if (value) {
					elm = new Node('meta', 1);
					elm.attr('name', name);
					elm.attr('content', value);
					elm.shortEnded = true;

					addHeadNode(elm);
				}
			});

			// Add/update/delete link
			elm = headerFragment.getAll('link')[0];
			if (elm && elm.attr('rel') == 'stylesheet') {
				if (data.stylesheet)
					elm.attr('href', data.stylesheet);
				else
					elm.remove();
			} else if (data.stylesheet) {
				elm = new Node('link', 1);
				elm.attr({
					rel : 'stylesheet',
					text : 'text/css',
					href : data.stylesheet
				});
				elm.shortEnded = true;

				addHeadNode(elm);
			}

			// Update body attributes
			elm = headerFragment.getAll('body')[0];
			if (elm) {
				setAttr(elm, 'dir', data.langdir);
				setAttr(elm, 'style', data.style);
				setAttr(elm, 'vlink', data.visited_color);
				setAttr(elm, 'link', data.link_color);
				setAttr(elm, 'alink', data.active_color);

				// Update iframe body as well
				dom.setAttribs(this.editor.getBody(), {
					style : data.style,
					dir : data.dir,
					vLink : data.visited_color,
					link : data.link_color,
					aLink : data.active_color
				});
			}

			// Set html attributes
			elm = headerFragment.getAll('html')[0];
			if (elm) {
				setAttr(elm, 'lang', data.langcode);
				setAttr(elm, 'xml:lang', data.langcode);
			}

			// Serialize header fragment and crop away body part
			html = new tinymce.html.Serializer({
				validate: false,
				indent: true,
				apply_source_formatting : true,
				indent_before: 'head,html,body,meta,title,script,link,style',
				indent_after: 'head,html,body,meta,title,script,link,style'
			}).serialize(headerFragment);

			this.head = html.substring(0, html.indexOf('</body>'));
		},

		_parseHeader : function() {
			// Parse the contents with a DOM parser
			return new tinymce.html.DomParser({
				validate: false,
				root_name: '#document'
			}).parse(this.head);
		},

		_setContent : function(ed, o) {
			var self = this, startPos, endPos, content = o.content, headerFragment, styles = '', dom = self.editor.dom, elm;

			function low(s) {
				return s.replace(/<\/?[A-Z]+/g, function(a) {
					return a.toLowerCase();
				})
			};

			// Ignore raw updated if we already have a head, this will fix issues with undo/redo keeping the head/foot separate
			if (o.format == 'raw' && self.head)
				return;

			if (o.source_view && ed.getParam('fullpage_hide_in_source_view'))
				return;

			// Parse out head, body and footer
			content = content.replace(/<(\/?)BODY/gi, '<$1body');
			startPos = content.indexOf('<body');

			if (startPos != -1) {
				startPos = content.indexOf('>', startPos);
				self.head = low(content.substring(0, startPos + 1));

				endPos = content.indexOf('</body', startPos);
				if (endPos == -1)
					endPos = content.length;

				o.content = content.substring(startPos + 1, endPos);
				self.foot = low(content.substring(endPos));
			} else {
				self.head = this._getDefaultHeader();
				self.foot = '\n</body>\n</html>';
			}

			// Parse header and update iframe
			headerFragment = self._parseHeader();
			each(headerFragment.getAll('style'), function(node) {
				if (node.firstChild)
					styles += node.firstChild.value;
			});

			elm = headerFragment.getAll('body')[0];
			if (elm) {
				dom.setAttribs(self.editor.getBody(), {
					style : elm.attr('style') || '',
					dir : elm.attr('dir') || '',
					vLink : elm.attr('vlink') || '',
					link : elm.attr('link') || '',
					aLink : elm.attr('alink') || ''
				});
			}

			dom.remove('fullpage_styles');

			if (styles) {
				dom.add(self.editor.getDoc().getElementsByTagName('head')[0], 'style', {id : 'fullpage_styles'}, styles);

				// Needed for IE 6/7
				elm = dom.get('fullpage_styles');
				if (elm.styleSheet)
					elm.styleSheet.cssText = styles;
			}
		},

		_getDefaultHeader : function() {
			var header = '', editor = this.editor, value, styles = '';

			if (editor.getParam('fullpage_default_xml_pi'))
				header += '<?xml version="1.0" encoding="' + editor.getParam('fullpage_default_encoding', 'ISO-8859-1') + '" ?>\n';

			header += editor.getParam('fullpage_default_doctype', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">');
			header += '\n<html>\n<head>\n';

			if (value = editor.getParam('fullpage_default_title'))
				header += '<title>' + value + '</title>\n';

			if (value = editor.getParam('fullpage_default_encoding'))
				header += '<meta http-equiv="Content-Type" content="text/html; charset=' + value + '" />\n';

			if (value = editor.getParam('fullpage_default_font_family'))
				styles += 'font-family: ' + value + ';';

			if (value = editor.getParam('fullpage_default_font_size'))
				styles += 'font-size: ' + value + ';';

			if (value = editor.getParam('fullpage_default_text_color'))
				styles += 'color: ' + value + ';';

			header += '</head>\n<body' + (styles ? ' style="' + styles + '"' : '') + '>\n';

			return header;
		},

		_getContent : function(ed, o) {
			var self = this;

			if (!o.source_view || !ed.getParam('fullpage_hide_in_source_view'))
				o.content = tinymce.trim(self.head) + '\n' + tinymce.trim(o.content) + '\n' + tinymce.trim(self.foot);
		}
	});

	// Register plugin
	tinymce.PluginManager.add('fullpage', tinymce.plugins.FullPagePlugin);
})();
