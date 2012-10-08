/**
 * editor_plugin_src.js
 *
 * Copyright 2011, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://tinymce.moxiecode.com/license
 * Contributing: http://tinymce.moxiecode.com/contributing
 */

(function() {
	var each = tinymce.each, Event = tinymce.dom.Event, bookmark;

	// Skips text nodes that only contain whitespace since they aren't semantically important.
	function skipWhitespaceNodes(e, next) {
		while (e && (e.nodeType === 8 || (e.nodeType === 3 && /^[ \t\n\r]*$/.test(e.nodeValue)))) {
			e = next(e);
		}
		return e;
	}

	function skipWhitespaceNodesBackwards(e) {
		return skipWhitespaceNodes(e, function(e) {
			return e.previousSibling;
		});
	}

	function skipWhitespaceNodesForwards(e) {
		return skipWhitespaceNodes(e, function(e) {
			return e.nextSibling;
		});
	}

	function hasParentInList(ed, e, list) {
		return ed.dom.getParent(e, function(p) {
			return tinymce.inArray(list, p) !== -1;
		});
	}

	function isList(e) {
		return e && (e.tagName === 'OL' || e.tagName === 'UL');
	}

	function splitNestedLists(element, dom) {
		var tmp, nested, wrapItem;
		tmp = skipWhitespaceNodesBackwards(element.lastChild);
		while (isList(tmp)) {
			nested = tmp;
			tmp = skipWhitespaceNodesBackwards(nested.previousSibling);
		}
		if (nested) {
			wrapItem = dom.create('li', { style: 'list-style-type: none;'});
			dom.split(element, nested);
			dom.insertAfter(wrapItem, nested);
			wrapItem.appendChild(nested);
			wrapItem.appendChild(nested);
			element = wrapItem.previousSibling;
		}
		return element;
	}

	function attemptMergeWithAdjacent(e, allowDifferentListStyles, mergeParagraphs) {
		e = attemptMergeWithPrevious(e, allowDifferentListStyles, mergeParagraphs);
		return attemptMergeWithNext(e, allowDifferentListStyles, mergeParagraphs);
	}

	function attemptMergeWithPrevious(e, allowDifferentListStyles, mergeParagraphs) {
		var prev = skipWhitespaceNodesBackwards(e.previousSibling);
		if (prev) {
			return attemptMerge(prev, e, allowDifferentListStyles ? prev : false, mergeParagraphs);
		} else {
			return e;
		}
	}

	function attemptMergeWithNext(e, allowDifferentListStyles, mergeParagraphs) {
		var next = skipWhitespaceNodesForwards(e.nextSibling);
		if (next) {
			return attemptMerge(e, next, allowDifferentListStyles ? next : false, mergeParagraphs);
		} else {
			return e;
		}
	}

	function attemptMerge(e1, e2, differentStylesMasterElement, mergeParagraphs) {
		if (canMerge(e1, e2, !!differentStylesMasterElement, mergeParagraphs)) {
			return merge(e1, e2, differentStylesMasterElement);
		} else if (e1 && e1.tagName === 'LI' && isList(e2)) {
			// Fix invalidly nested lists.
			e1.appendChild(e2);
		}
		return e2;
	}

	function canMerge(e1, e2, allowDifferentListStyles, mergeParagraphs) {
		if (!e1 || !e2) {
			return false;
		} else if (e1.tagName === 'LI' && e2.tagName === 'LI') {
			return e2.style.listStyleType === 'none' || containsOnlyAList(e2);
		} else if (isList(e1)) {
			return (e1.tagName === e2.tagName && (allowDifferentListStyles || e1.style.listStyleType === e2.style.listStyleType)) || isListForIndent(e2);
		} else return mergeParagraphs && e1.tagName === 'P' && e2.tagName === 'P';
	}

	function isListForIndent(e) {
		var firstLI = skipWhitespaceNodesForwards(e.firstChild), lastLI = skipWhitespaceNodesBackwards(e.lastChild);
		return firstLI && lastLI && isList(e) && firstLI === lastLI && (isList(firstLI) || firstLI.style.listStyleType === 'none' || containsOnlyAList(firstLI));
	}

	function containsOnlyAList(e) {
		var firstChild = skipWhitespaceNodesForwards(e.firstChild), lastChild = skipWhitespaceNodesBackwards(e.lastChild);
		return firstChild && lastChild && firstChild === lastChild && isList(firstChild);
	}

	function merge(e1, e2, masterElement) {
		var lastOriginal = skipWhitespaceNodesBackwards(e1.lastChild), firstNew = skipWhitespaceNodesForwards(e2.firstChild);
		if (e1.tagName === 'P') {
			e1.appendChild(e1.ownerDocument.createElement('br'));
		}
		while (e2.firstChild) {
			e1.appendChild(e2.firstChild);
		}
		if (masterElement) {
			e1.style.listStyleType = masterElement.style.listStyleType;
		}
		e2.parentNode.removeChild(e2);
		attemptMerge(lastOriginal, firstNew, false);
		return e1;
	}

	function findItemToOperateOn(e, dom) {
		var item;
		if (!dom.is(e, 'li,ol,ul')) {
			item = dom.getParent(e, 'li');
			if (item) {
				e = item;
			}
		}
		return e;
	}

	tinymce.create('tinymce.plugins.Lists', {
		init: function(ed) {
			var LIST_TABBING = 'TABBING';
			var LIST_EMPTY_ITEM = 'EMPTY';
			var LIST_ESCAPE = 'ESCAPE';
			var LIST_PARAGRAPH = 'PARAGRAPH';
			var LIST_UNKNOWN = 'UNKNOWN';
			var state = LIST_UNKNOWN;

			function isTabInList(e) {
				// Don't indent on Ctrl+Tab or Alt+Tab
				return e.keyCode === tinymce.VK.TAB && !(e.altKey || e.ctrlKey) &&
					(ed.queryCommandState('InsertUnorderedList') || ed.queryCommandState('InsertOrderedList'));
			}

			function isOnLastListItem() {
				var li = getLi();
				var grandParent = li.parentNode.parentNode;
				var isLastItem = li.parentNode.lastChild === li;
				return isLastItem && !isNestedList(grandParent) && isEmptyListItem(li);
			}

			function isNestedList(grandParent) {
				if (isList(grandParent)) {
					return grandParent.parentNode && grandParent.parentNode.tagName === 'LI';
				} else {
					return  grandParent.tagName === 'LI';
				}
			}

			function isInEmptyListItem() {
				return ed.selection.isCollapsed() && isEmptyListItem(getLi());
			}

			function getLi() {
				var n = ed.selection.getStart();
				// Get start will return BR if the LI only contains a BR or an empty element as we use these to fix caret position
				return ((n.tagName == 'BR' || n.tagName == '') && n.parentNode.tagName == 'LI') ? n.parentNode : n;
			}

			function isEmptyListItem(li) {
				var numChildren = li.childNodes.length;
				if (li.tagName === 'LI') {
					return numChildren == 0 ? true : numChildren == 1 && (li.firstChild.tagName == '' || li.firstChild.tagName == 'BR' || isEmptyIE9Li(li));
				}
				return false;
			}

			function isEmptyIE9Li(li) {
				// only consider this to be last item if there is no list item content or that content is nbsp or space since IE9 creates these
				var lis = tinymce.grep(li.parentNode.childNodes, function(n) {return n.tagName == 'LI'});
				var isLastLi = li == lis[lis.length - 1];
				var child = li.firstChild;
				return tinymce.isIE9 && isLastLi && (child.nodeValue == String.fromCharCode(160) || child.nodeValue == String.fromCharCode(32));
			}

			function isEnter(e) {
				return e.keyCode === tinymce.VK.ENTER;
			}

			function isEnterWithoutShift(e) {
				return isEnter(e) && !e.shiftKey;
			}

			function getListKeyState(e) {
				if (isTabInList(e)) {
					return LIST_TABBING;
				} else if (isEnterWithoutShift(e) && isOnLastListItem()) {
					// Returns LIST_UNKNOWN since breaking out of lists is handled by the EnterKey.js logic now
					//return LIST_ESCAPE;
					return LIST_UNKNOWN;
				} else if (isEnterWithoutShift(e) && isInEmptyListItem()) {
					return LIST_EMPTY_ITEM;
				} else {
					return LIST_UNKNOWN;
				}
			}

			function cancelDefaultEvents(ed, e) {
				// list escape is done manually using outdent as it does not create paragraphs correctly in td's
				if (state == LIST_TABBING || state == LIST_EMPTY_ITEM || tinymce.isGecko && state == LIST_ESCAPE) {
					Event.cancel(e);
				}
			}

			function isCursorAtEndOfContainer() {
				var range = ed.selection.getRng(true);
				var startContainer = range.startContainer;
				if (startContainer.nodeType == 3) {
					var value = startContainer.nodeValue;
					if (tinymce.isIE9 && value.length > 1 && value.charCodeAt(value.length-1) == 32) {
						// IE9 places a space on the end of the text in some cases so ignore last char
						return (range.endOffset == value.length-1);
					} else {
						return (range.endOffset == value.length);
					}
				} else if (startContainer.nodeType == 1) {
					return range.endOffset == startContainer.childNodes.length;
				}
				return false;
			}

			/*
			 	If we are at the end of a list item surrounded with an element, pressing enter should create a
			 	new list item instead without splitting the element e.g. don't want to create new P or H1 tag
			  */
			function isEndOfListItem() {
				var node = ed.selection.getNode();
				var validElements = 'h1,h2,h3,h4,h5,h6,p,div';
				var isLastParagraphOfLi = ed.dom.is(node, validElements) && node.parentNode.tagName === 'LI' && node.parentNode.lastChild === node;
				return ed.selection.isCollapsed() && isLastParagraphOfLi && isCursorAtEndOfContainer();
			}

			// Creates a new list item after the current selection's list item parent
			function createNewLi(ed, e) {
				if (isEnterWithoutShift(e) && isEndOfListItem()) {
					var node = ed.selection.getNode();
					var li = ed.dom.create("li");
					var parentLi = ed.dom.getParent(node, 'li');
					ed.dom.insertAfter(li, parentLi);

					// Move caret to new list element.
					if (tinymce.isIE6 || tinymce.isIE7 || tinyMCE.isIE8) {
						// Removed this line since it would create an odd <&nbsp;> tag and placing the caret inside an empty LI is handled and should be handled by the selection logic
						//li.appendChild(ed.dom.create("&nbsp;")); // IE needs an element within the bullet point
						ed.selection.setCursorLocation(li, 1);
					} else {
						ed.selection.setCursorLocation(li, 0);
					}
					e.preventDefault();
				}
			}

			function imageJoiningListItem(ed, e) {
				var prevSibling;

				if (!tinymce.isGecko)
					return;

				var n = ed.selection.getStart();
				if (e.keyCode != tinymce.VK.BACKSPACE || n.tagName !== 'IMG')
					return;

				function lastLI(node) {
					var child = node.firstChild;
					var li = null;
					do {
						if (!child)
							break;

						if (child.tagName === 'LI')
							li = child;
					} while (child = child.nextSibling);

					return li;
				}

				function addChildren(parentNode, destination) {
					while (parentNode.childNodes.length > 0)
						destination.appendChild(parentNode.childNodes[0]);
				}

				// Check if there is a previous sibling
				prevSibling = n.parentNode.previousSibling;
				if (!prevSibling)
					return;

				var ul;
				if (prevSibling.tagName === 'UL' || prevSibling.tagName === 'OL')
					ul = prevSibling;
				else if (prevSibling.previousSibling && (prevSibling.previousSibling.tagName === 'UL' || prevSibling.previousSibling.tagName === 'OL'))
					ul = prevSibling.previousSibling;
				else
					return;

				var li = lastLI(ul);

				// move the caret to the end of the list item
				var rng = ed.dom.createRng();
				rng.setStart(li, 1);
				rng.setEnd(li, 1);
				ed.selection.setRng(rng);
				ed.selection.collapse(true);

				// save a bookmark at the end of the list item
				var bookmark = ed.selection.getBookmark();

				// copy the image an its text to the list item
				var clone = n.parentNode.cloneNode(true);
				if (clone.tagName === 'P' || clone.tagName === 'DIV')
					addChildren(clone, li);
				else
					li.appendChild(clone);

				// remove the old copy of the image
				n.parentNode.parentNode.removeChild(n.parentNode);

				// move the caret where we saved the bookmark
				ed.selection.moveToBookmark(bookmark);
			}

			// fix the cursor position to ensure it is correct in IE
			function setCursorPositionToOriginalLi(li) {
				var list = ed.dom.getParent(li, 'ol,ul');
				if (list != null) {
					var lastLi = list.lastChild;
					// Removed this line since IE9 would report an DOM character error and placing the caret inside an empty LI is handled and should be handled by the selection logic
					//lastLi.appendChild(ed.getDoc().createElement(''));
					ed.selection.setCursorLocation(lastLi, 0);
				}
			}

			this.ed = ed;
			ed.addCommand('Indent', this.indent, this);
			ed.addCommand('Outdent', this.outdent, this);
			ed.addCommand('InsertUnorderedList', function() {
				this.applyList('UL', 'OL');
			}, this);
			ed.addCommand('InsertOrderedList', function() {
				this.applyList('OL', 'UL');
			}, this);

			ed.onInit.add(function() {
				ed.editorCommands.addCommands({
					'outdent': function() {
						var sel = ed.selection, dom = ed.dom;

						function hasStyleIndent(n) {
							n = dom.getParent(n, dom.isBlock);
							return n && (parseInt(ed.dom.getStyle(n, 'margin-left') || 0, 10) + parseInt(ed.dom.getStyle(n, 'padding-left') || 0, 10)) > 0;
						}

						return hasStyleIndent(sel.getStart()) || hasStyleIndent(sel.getEnd()) || ed.queryCommandState('InsertOrderedList') || ed.queryCommandState('InsertUnorderedList');
					}
				}, 'state');
			});

			ed.onKeyUp.add(function(ed, e) {
				if (state == LIST_TABBING) {
					ed.execCommand(e.shiftKey ? 'Outdent' : 'Indent', true, null);
					state = LIST_UNKNOWN;
					return Event.cancel(e);
				} else if (state == LIST_EMPTY_ITEM) {
					var li = getLi();
					var shouldOutdent =  ed.settings.list_outdent_on_enter === true || e.shiftKey;
					ed.execCommand(shouldOutdent ? 'Outdent' : 'Indent', true, null);
					if (tinymce.isIE) {
						setCursorPositionToOriginalLi(li);
					}

					return Event.cancel(e);
				} else if (state == LIST_ESCAPE) {
					if (tinymce.isIE6 || tinymce.isIE7 || tinymce.isIE8) {
						// append a zero sized nbsp so that caret is positioned correctly in IE after escaping and applying formatting.
						// if there is no text then applying formatting for e.g a H1 to the P tag immediately following list after
						// escaping from it will cause the caret to be positioned on the last li instead of staying the in P tag.
						var n = ed.getDoc().createTextNode('\uFEFF');
						ed.selection.getNode().appendChild(n);
					} else if (tinymce.isIE9 || tinymce.isGecko) {
						// IE9 does not escape the list so we use outdent to do this and cancel the default behaviour
						// Gecko does not create a paragraph outdenting inside a TD so default behaviour is cancelled and we outdent ourselves
						ed.execCommand('Outdent');
						return Event.cancel(e);
					}
				}
			});

			function fixListItem(parent, reference) {
				// a zero-sized non-breaking space is placed in the empty list item so that the nested list is
				// displayed on the below line instead of next to it
				var n = ed.getDoc().createTextNode('\uFEFF');
				parent.insertBefore(n, reference);
				ed.selection.setCursorLocation(n, 0);
				// repaint to remove rendering artifact. only visible when creating new list
				ed.execCommand('mceRepaint');
			}

			function fixIndentedListItemForGecko(ed, e) {
				if (isEnter(e)) {
					var li = getLi();
					if (li) {
						var parent = li.parentNode;
						var grandParent = parent && parent.parentNode;
						if (grandParent && grandParent.nodeName == 'LI' && grandParent.firstChild == parent && li == parent.firstChild) {
							fixListItem(grandParent, parent);
						}
					}
				}
			}

			function fixIndentedListItemForIE8(ed, e) {
				if (isEnter(e)) {
					var li = getLi();
					if (ed.dom.select('ul li', li).length === 1) {
						var list = li.firstChild;
						fixListItem(li, list);
					}
				}
			}

			function fixDeletingFirstCharOfList(ed, e) {
				function listElements(li) {
					var elements = [];
					var walker = new tinymce.dom.TreeWalker(li.firstChild, li);
					for (var node = walker.current(); node; node = walker.next()) {
						if (ed.dom.is(node, 'ol,ul,li')) {
							elements.push(node);
						}
					}
					return elements;
				}

				if (e.keyCode == tinymce.VK.BACKSPACE) {
					var li = getLi();
					if (li) {
						var list = ed.dom.getParent(li, 'ol,ul'),
							rng  = ed.selection.getRng();
						if (list && list.firstChild === li && rng.startOffset == 0) {
							var elements = listElements(li);
							elements.unshift(li);
							ed.execCommand("Outdent", false, elements);
							ed.undoManager.add();
							return Event.cancel(e);
						}
					}
				}
			}

			function fixDeletingEmptyLiInWebkit(ed, e) {
				var li = getLi();
				if (e.keyCode === tinymce.VK.BACKSPACE && ed.dom.is(li, 'li') && li.parentNode.firstChild!==li) {
					if (ed.dom.select('ul,ol', li).length === 1) {
						var prevLi = li.previousSibling;
						ed.dom.remove(ed.dom.select('br', li));
						ed.dom.remove(li, true);
						var textNodes = tinymce.grep(prevLi.childNodes, function(n){ return n.nodeType === 3 });
						if (textNodes.length === 1) {
							var textNode = textNodes[0];
							ed.selection.setCursorLocation(textNode, textNode.length);
						}
						ed.undoManager.add();
						return Event.cancel(e);
					}
				}
			}

			ed.onKeyDown.add(function(_, e) { state = getListKeyState(e); });
			ed.onKeyDown.add(cancelDefaultEvents);
			ed.onKeyDown.add(imageJoiningListItem);
			ed.onKeyDown.add(createNewLi);

			if (tinymce.isGecko) {
				ed.onKeyUp.add(fixIndentedListItemForGecko);
			}
			if (tinymce.isIE8) {
				ed.onKeyUp.add(fixIndentedListItemForIE8);
			}
			if (tinymce.isGecko || tinymce.isWebKit) {
				ed.onKeyDown.add(fixDeletingFirstCharOfList);
			}
			if (tinymce.isWebKit) {
				ed.onKeyDown.add(fixDeletingEmptyLiInWebkit);
			}
		},

		applyList: function(targetListType, oppositeListType) {
			var t = this, ed = t.ed, dom = ed.dom, applied = [], hasSameType = false, hasOppositeType = false, hasNonList = false, actions,
					selectedBlocks = ed.selection.getSelectedBlocks();

			function cleanupBr(e) {
				if (e && e.tagName === 'BR') {
					dom.remove(e);
				}
			}

			function makeList(element) {
				var list = dom.create(targetListType), li;

				function adjustIndentForNewList(element) {
					// If there's a margin-left, outdent one level to account for the extra list margin.
					if (element.style.marginLeft || element.style.paddingLeft) {
						t.adjustPaddingFunction(false)(element);
					}
				}

				if (element.tagName === 'LI') {
					// No change required.
				} else if (element.tagName === 'P' || element.tagName === 'DIV' || element.tagName === 'BODY') {
					processBrs(element, function(startSection, br) {
						doWrapList(startSection, br, element.tagName === 'BODY' ? null : startSection.parentNode);
						li = startSection.parentNode;
						adjustIndentForNewList(li);
						cleanupBr(br);
					});
					if (li) {
						if (li.tagName === 'LI' && (element.tagName === 'P' || selectedBlocks.length > 1)) {
							dom.split(li.parentNode.parentNode, li.parentNode);
						}
						attemptMergeWithAdjacent(li.parentNode, true);
					}
					return;
				} else {
					// Put the list around the element.
					li = dom.create('li');
					dom.insertAfter(li, element);
					li.appendChild(element);
					adjustIndentForNewList(element);
					element = li;
				}
				dom.insertAfter(list, element);
				list.appendChild(element);
				attemptMergeWithAdjacent(list, true);
				applied.push(element);
			}

			function doWrapList(start, end, template) {
				var li, n = start, tmp;
				while (!dom.isBlock(start.parentNode) && start.parentNode !== dom.getRoot()) {
					start = dom.split(start.parentNode, start.previousSibling);
					start = start.nextSibling;
					n = start;
				}
				if (template) {
					li = template.cloneNode(true);
					start.parentNode.insertBefore(li, start);
					while (li.firstChild) dom.remove(li.firstChild);
					li = dom.rename(li, 'li');
				} else {
					li = dom.create('li');
					start.parentNode.insertBefore(li, start);
				}
				while (n && n != end) {
					tmp = n.nextSibling;
					li.appendChild(n);
					n = tmp;
				}
				if (li.childNodes.length === 0) {
					li.innerHTML = '<br _mce_bogus="1" />';
				}
				makeList(li);
			}

			function processBrs(element, callback) {
				var startSection, previousBR, END_TO_START = 3, START_TO_END = 1,
						breakElements = 'br,ul,ol,p,div,h1,h2,h3,h4,h5,h6,table,blockquote,address,pre,form,center,dl';

				function isAnyPartSelected(start, end) {
					var r = dom.createRng(), sel;
					bookmark.keep = true;
					ed.selection.moveToBookmark(bookmark);
					bookmark.keep = false;
					sel = ed.selection.getRng(true);
					if (!end) {
						end = start.parentNode.lastChild;
					}
					r.setStartBefore(start);
					r.setEndAfter(end);
					return !(r.compareBoundaryPoints(END_TO_START, sel) > 0 || r.compareBoundaryPoints(START_TO_END, sel) <= 0);
				}

				function nextLeaf(br) {
					if (br.nextSibling)
						return br.nextSibling;
					if (!dom.isBlock(br.parentNode) && br.parentNode !== dom.getRoot())
						return nextLeaf(br.parentNode);
				}

				// Split on BRs within the range and process those.
				startSection = element.firstChild;
				// First mark the BRs that have any part of the previous section selected.
				var trailingContentSelected = false;
				each(dom.select(breakElements, element), function(br) {
					if (br.hasAttribute && br.hasAttribute('_mce_bogus')) {
						return true; // Skip the bogus Brs that are put in to appease Firefox and Safari.
					}
					if (isAnyPartSelected(startSection, br)) {
						dom.addClass(br, '_mce_tagged_br');
						startSection = nextLeaf(br);
					}
				});
				trailingContentSelected = (startSection && isAnyPartSelected(startSection, undefined));
				startSection = element.firstChild;
				each(dom.select(breakElements, element), function(br) {
					// Got a section from start to br.
					var tmp = nextLeaf(br);
					if (br.hasAttribute && br.hasAttribute('_mce_bogus')) {
						return true; // Skip the bogus Brs that are put in to appease Firefox and Safari.
					}
					if (dom.hasClass(br, '_mce_tagged_br')) {
						callback(startSection, br, previousBR);
						previousBR = null;
					} else {
						previousBR = br;
					}
					startSection = tmp;
				});
				if (trailingContentSelected) {
					callback(startSection, undefined, previousBR);
				}
			}

			function wrapList(element) {
				processBrs(element, function(startSection, br, previousBR) {
					// Need to indent this part
					doWrapList(startSection, br);
					cleanupBr(br);
					cleanupBr(previousBR);
				});
			}

			function changeList(element) {
				if (tinymce.inArray(applied, element) !== -1) {
					return;
				}
				if (element.parentNode.tagName === oppositeListType) {
					dom.split(element.parentNode, element);
					makeList(element);
					attemptMergeWithNext(element.parentNode, false);
				}
				applied.push(element);
			}

			function convertListItemToParagraph(element) {
				var child, nextChild, mergedElement, splitLast;
				if (tinymce.inArray(applied, element) !== -1) {
					return;
				}
				element = splitNestedLists(element, dom);
				while (dom.is(element.parentNode, 'ol,ul,li')) {
					dom.split(element.parentNode, element);
				}
				// Push the original element we have from the selection, not the renamed one.
				applied.push(element);
				element = dom.rename(element, 'p');
				mergedElement = attemptMergeWithAdjacent(element, false, ed.settings.force_br_newlines);
				if (mergedElement === element) {
					// Now split out any block elements that can't be contained within a P.
					// Manually iterate to ensure we handle modifications correctly (doesn't work with tinymce.each)
					child = element.firstChild;
					while (child) {
						if (dom.isBlock(child)) {
							child = dom.split(child.parentNode, child);
							splitLast = true;
							nextChild = child.nextSibling && child.nextSibling.firstChild;
						} else {
							nextChild = child.nextSibling;
							if (splitLast && child.tagName === 'BR') {
								dom.remove(child);
							}
							splitLast = false;
						}
						child = nextChild;
					}
				}
			}

			each(selectedBlocks, function(e) {
				e = findItemToOperateOn(e, dom);
				if (e.tagName === oppositeListType || (e.tagName === 'LI' && e.parentNode.tagName === oppositeListType)) {
					hasOppositeType = true;
				} else if (e.tagName === targetListType || (e.tagName === 'LI' && e.parentNode.tagName === targetListType)) {
					hasSameType = true;
				} else {
					hasNonList = true;
				}
			});

			if (hasNonList &&!hasSameType || hasOppositeType || selectedBlocks.length === 0) {
				actions = {
					'LI': changeList,
					'H1': makeList,
					'H2': makeList,
					'H3': makeList,
					'H4': makeList,
					'H5': makeList,
					'H6': makeList,
					'P': makeList,
					'BODY': makeList,
					'DIV': selectedBlocks.length > 1 ? makeList : wrapList,
					defaultAction: wrapList,
					elements: this.selectedBlocks()
				};
			} else {
				actions = {
					defaultAction: convertListItemToParagraph,
					elements: this.selectedBlocks(),
					processEvenIfEmpty: true
				};
			}
			this.process(actions);
		},

		indent: function() {
			var ed = this.ed, dom = ed.dom, indented = [];

			function createWrapItem(element) {
				var wrapItem = dom.create('li', { style: 'list-style-type: none;'});
				dom.insertAfter(wrapItem, element);
				return wrapItem;
			}

			function createWrapList(element) {
				var wrapItem = createWrapItem(element),
						list = dom.getParent(element, 'ol,ul'),
						listType = list.tagName,
						listStyle = dom.getStyle(list, 'list-style-type'),
						attrs = {},
						wrapList;
				if (listStyle !== '') {
					attrs.style = 'list-style-type: ' + listStyle + ';';
				}
				wrapList = dom.create(listType, attrs);
				wrapItem.appendChild(wrapList);
				return wrapList;
			}

			function indentLI(element) {
				if (!hasParentInList(ed, element, indented)) {
					element = splitNestedLists(element, dom);
					var wrapList = createWrapList(element);
					wrapList.appendChild(element);
					attemptMergeWithAdjacent(wrapList.parentNode, false);
					attemptMergeWithAdjacent(wrapList, false);
					indented.push(element);
				}
			}

			this.process({
				'LI': indentLI,
				defaultAction: this.adjustPaddingFunction(true),
				elements: this.selectedBlocks()
			});

		},

		outdent: function(ui, elements) {
			var t = this, ed = t.ed, dom = ed.dom, outdented = [];

			function outdentLI(element) {
				var listElement, targetParent, align;
				if (!hasParentInList(ed, element, outdented)) {
					if (dom.getStyle(element, 'margin-left') !== '' || dom.getStyle(element, 'padding-left') !== '') {
						return t.adjustPaddingFunction(false)(element);
					}
					align = dom.getStyle(element, 'text-align', true);
					if (align === 'center' || align === 'right') {
						dom.setStyle(element, 'text-align', 'left');
						return;
					}
					element = splitNestedLists(element, dom);
					listElement = element.parentNode;
					targetParent = element.parentNode.parentNode;
					if (targetParent.tagName === 'P') {
						dom.split(targetParent, element.parentNode);
					} else {
						dom.split(listElement, element);
						if (targetParent.tagName === 'LI') {
							// Nested list, need to split the LI and go back out to the OL/UL element.
							dom.split(targetParent, element);
						} else if (!dom.is(targetParent, 'ol,ul')) {
							dom.rename(element, 'p');
						}
					}
					outdented.push(element);
				}
			}

			var listElements = elements && tinymce.is(elements, 'array') ? elements : this.selectedBlocks();
			this.process({
				'LI': outdentLI,
				defaultAction: this.adjustPaddingFunction(false),
				elements: listElements
			});

			each(outdented, attemptMergeWithAdjacent);
		},

		process: function(actions) {
			var t = this, sel = t.ed.selection, dom = t.ed.dom, selectedBlocks, r;

			function isEmptyElement(element) {
				var excludeBrsAndBookmarks = tinymce.grep(element.childNodes, function(n) {
					return !(n.nodeName === 'BR' || n.nodeName === 'SPAN' && dom.getAttrib(n, 'data-mce-type') == 'bookmark'
							|| n.nodeType == 3 && (n.nodeValue == String.fromCharCode(160) || n.nodeValue == ''));
				});
				return excludeBrsAndBookmarks.length === 0;
			}

			function processElement(element) {
				dom.removeClass(element, '_mce_act_on');
				if (!element || element.nodeType !== 1 || ! actions.processEvenIfEmpty && selectedBlocks.length > 1 && isEmptyElement(element)) {
					return;
				}
				element = findItemToOperateOn(element, dom);
				var action = actions[element.tagName];
				if (!action) {
					action = actions.defaultAction;
				}
				action(element);
			}

			function recurse(element) {
				t.splitSafeEach(element.childNodes, processElement, true);
			}

			function brAtEdgeOfSelection(container, offset) {
				return offset >= 0 && container.hasChildNodes() && offset < container.childNodes.length &&
						container.childNodes[offset].tagName === 'BR';
			}

			function isInTable() {
				var n = sel.getNode();
				var p = dom.getParent(n, 'td');
				return p !== null;
			}

			selectedBlocks = actions.elements;

			r = sel.getRng(true);
			if (!r.collapsed) {
				if (brAtEdgeOfSelection(r.endContainer, r.endOffset - 1)) {
					r.setEnd(r.endContainer, r.endOffset - 1);
					sel.setRng(r);
				}
				if (brAtEdgeOfSelection(r.startContainer, r.startOffset)) {
					r.setStart(r.startContainer, r.startOffset + 1);
					sel.setRng(r);
				}
			}


			if (tinymce.isIE8) {
				// append a zero sized nbsp so that caret is restored correctly using bookmark
				var s = t.ed.selection.getNode();
				if (s.tagName === 'LI' && !(s.parentNode.lastChild === s)) {
					var i = t.ed.getDoc().createTextNode('\uFEFF');
					s.appendChild(i);
				}
			}

			bookmark = sel.getBookmark();
			actions.OL = actions.UL = recurse;
			t.splitSafeEach(selectedBlocks, processElement);
			sel.moveToBookmark(bookmark);
			bookmark = null;

			// we avoid doing repaint in a table as this will move the caret out of the table in Firefox 3.6
			if (!isInTable()) {
				// Avoids table or image handles being left behind in Firefox.
				t.ed.execCommand('mceRepaint');
			}
		},

		splitSafeEach: function(elements, f, forceClassBase) {
			if (forceClassBase ||
				(tinymce.isGecko &&
					(/Firefox\/[12]\.[0-9]/.test(navigator.userAgent) ||
					 /Firefox\/3\.[0-4]/.test(navigator.userAgent)))) {
				this.classBasedEach(elements, f);
			} else {
				each(elements, f);
			}
		},

		classBasedEach: function(elements, f) {
			var dom = this.ed.dom, nodes, element;
			// Mark nodes
			each(elements, function(element) {
				dom.addClass(element, '_mce_act_on');
			});
			nodes = dom.select('._mce_act_on');
			while (nodes.length > 0) {
				element = nodes.shift();
				dom.removeClass(element, '_mce_act_on');
				f(element);
				nodes = dom.select('._mce_act_on');
			}
		},

		adjustPaddingFunction: function(isIndent) {
			var indentAmount, indentUnits, ed = this.ed;
			indentAmount = ed.settings.indentation;
			indentUnits = /[a-z%]+/i.exec(indentAmount);
			indentAmount = parseInt(indentAmount, 10);
			return function(element) {
				var currentIndent, newIndentAmount;
				currentIndent = parseInt(ed.dom.getStyle(element, 'margin-left') || 0, 10) + parseInt(ed.dom.getStyle(element, 'padding-left') || 0, 10);
				if (isIndent) {
					newIndentAmount = currentIndent + indentAmount;
				} else {
					newIndentAmount = currentIndent - indentAmount;
				}
				ed.dom.setStyle(element, 'padding-left', '');
				ed.dom.setStyle(element, 'margin-left', newIndentAmount > 0 ? newIndentAmount + indentUnits : '');
			};
		},

		selectedBlocks: function() {
			var ed = this.ed, selectedBlocks = ed.selection.getSelectedBlocks();
			return selectedBlocks.length == 0 ? [ ed.dom.getRoot() ] : selectedBlocks;
		},

		getInfo: function() {
			return {
				longname : 'Lists',
				author : 'Moxiecode Systems AB',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/lists',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});
	tinymce.PluginManager.add("lists", tinymce.plugins.Lists);
}());
