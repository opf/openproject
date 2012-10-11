/**
 * ins.js
 *
 * Copyright 2009, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://tinymce.moxiecode.com/license
 * Contributing: http://tinymce.moxiecode.com/contributing
 */

function init() {
	SXE.initElementDialog('ins');
	if (SXE.currentAction == "update") {
		setFormValue('datetime', tinyMCEPopup.editor.dom.getAttrib(SXE.updateElement, 'datetime'));
		setFormValue('cite', tinyMCEPopup.editor.dom.getAttrib(SXE.updateElement, 'cite'));
		SXE.showRemoveButton();
	}
}

function setElementAttribs(elm) {
	setAllCommonAttribs(elm);
	setAttrib(elm, 'datetime');
	setAttrib(elm, 'cite');
	elm.removeAttribute('data-mce-new');
}

function insertIns() {
	var elm = tinyMCEPopup.editor.dom.getParent(SXE.focusElement, 'INS');

	if (elm == null) {
		var s = SXE.inst.selection.getContent();
		if(s.length > 0) {
			insertInlineElement('ins');
			var elementArray = SXE.inst.dom.select('ins[data-mce-new]');
			for (var i=0; i<elementArray.length; i++) {
				var elm = elementArray[i];
				setElementAttribs(elm);
			}
		}
	} else {
		setElementAttribs(elm);
	}
	tinyMCEPopup.editor.nodeChanged();
	tinyMCEPopup.execCommand('mceEndUndoLevel');
	tinyMCEPopup.close();
}

function removeIns() {
	SXE.removeElement('ins');
	tinyMCEPopup.close();
}

tinyMCEPopup.onInit.add(init);
