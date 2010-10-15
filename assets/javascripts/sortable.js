/*
Table sorting script  by Joost de Valk, check it out at http://www.joostdevalk.nl/code/sortable-table/.
Based on a script from http://www.kryogenix.org/code/browser/sorttable/.
Distributed under the MIT license: http://www.kryogenix.org/code/browser/licence.html .

Copyright (c) 1997-2007 Stuart Langridge, Joost de Valk.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Version 1.5.7
*/

/* You can change these values */
var europeandate = true;
var alternate_row_colors = true;

/* Don't change anything below this unless you know what you're doing */
// addEvent(window, "load", sortables_init);

var SORT_COLUMN_INDEX;
var thead = false;

function alternate(table) {
	// Take object table and get all it's tbodies.
	var i, j, tableBodies, tableRows;
	tableBodies = table.getElementsByTagName("tbody");
	// Loop through these tbodies
	for (i = 0; i < tableBodies.length; i += 1) {
		// Take the tbody, and get all it's rows
		tableRows = tableBodies[i].getElementsByTagName("tr");
		// Loop through these rows
		// Start at 1 because we want to leave the heading row untouched
		for (j = 0; j < tableRows.length; j += 1) {
			// Check if j is even, and apply classes for both possible results
			if ((j % 2) === 0) {
				if (tableRows[j].className.indexOf('odd') !== -1) {
					tableRows[j].className = tableRows[j].className.replace('odd', 'even');
				} else {
					if (tableRows[j].className.indexOf('even') === -1) {
						tableRows[j].className += " even";
					}
				}
			} else {
				if (tableRows[j].className.indexOf('even') !== -1) {
					tableRows[j].className = tableRows[j].className.replace('even', 'odd');
				} else {
					if (tableRows[j].className.indexOf('odd') === -1) {
						tableRows[j].className += " odd";
					}
				}
			}
		}
	}
}

function ts_getInnerText(el) {
	if (typeof el === "string") {
		return el;
	}
	if (typeof el === "undefined") {
		return el;
	}
	if (el.innerText) {
		return el.innerText;
	}	//Not needed but it is faster
	var str, cs, l, i;
	str = "";

	cs = el.childNodes;
	l = cs.length;
	for (i = 0; i < l; i += 1) {
		switch (cs[i].nodeType) {
		case 1: //ELEMENT_NODE
			str += ts_getInnerText(cs[i]);
			break;
		case 3:	//TEXT_NODE
			str += cs[i].nodeValue;
			break;
		}
	}
	return str;
}

function ts_makeSortable(t) {
	var firstRow, i, cell, txt;
	if (t.rows && t.rows.length > 0) {
		if (t.tHead && t.tHead.rows.length > 0) {
			firstRow = t.tHead.rows[t.tHead.rows.length - 1];
			thead = true;
		} else {
			firstRow = t.rows[0];
		}
	}
	if (!firstRow) {
		return;
	}

	// We have a first row: assume it's the header, and make its contents clickable links
	for (i = 0; i < firstRow.cells.length; i += 1) {
		cell = firstRow.cells[i];
		txt = ts_getInnerText(cell);
		if (cell.className !== "unsortable" && cell.className.indexOf("unsortable") === -1) {
			cell.innerHTML = '<a href="#" class="sortheader sort" onclick="ts_resortTable(this, ' +
				i +
				');return false;">' +
				txt +
				'</a>';
		}
	}
	if (alternate_row_colors) {
		alternate(t);
	}
}

function sortables_init() {
	// Find table with id sortable-table and make them sortable
	if (!document.getElementById) {
		return;
	}
	var tbl = document.getElementById("sortable-table");
	ts_makeSortable(tbl);
}

function getParent(el, pTagName) {
	if (el === null) {
		return null;
	} else if (el.nodeType === 1 && el.tagName.toLowerCase() === pTagName.toLowerCase()) {
		return el;
	} else {
		return getParent(el.parentNode, pTagName);
	}
}

function ts_get_cell_data(a, idx) {
	var acell, aa;
	if ((typeof idx) === "undefined") {
		acell = a.cells[SORT_COLUMN_INDEX];
	} else {
		acell = a.cells[idx];
	}
	if ((aa = acell.getAttribute("raw-data")) === null) {
		aa = ts_getInnerText(acell).toLowerCase();
	}
	return aa;
}

function compare_numeric(a, b) {
	var af, bf;
	af = parseFloat(a);
	af = (isNaN(af) ? 0 : af);
	bf = parseFloat(b);
	bf = (isNaN(bf) ? 0 : bf);
	return af - bf;
}

function ts_sort_numeric(a, b) {
	var cells = [ts_get_cell_data(a), ts_get_cell_data(b)];
	return compare_numeric(cells[0], cells[1]);
}

function ts_sort_caseinsensitive(a, b) {
	var cells = [ts_get_cell_data(a), ts_get_cell_data(b)];
	if (cells[0] === cells[1]) {
		return 0;
	}
	if (cells[0] < cells[1]) {
		return -1;
	}
	return 1;
}

function trim(s) {
	return s.replace(/^\s+|\s+$/g, "");
}

function ts_resortTable(lnk, clid) {
	var td, column, t, first, itm, i, j, k, numeric_flag, all_sort_links, ci, firstRow, newRows, sortfn;
	td = lnk.parentNode;
	column = clid || td.cellIndex;
	t = getParent(td, 'TABLE');

	// Do not sort single a row
	if (t.rows.length <= 1) {
		return;
	}

	// Determine if all rows are equal
	first = ts_get_cell_data(t.tBodies[0].rows[0], 0);
	itm = first;
	i = 0;
	while (itm === first && i < t.tBodies[0].rows.length) {
		itm = ts_get_cell_data(t.tBodies[0].rows[i], column);
		itm = trim(itm);
		if (itm.substr(0, 4) === "<!--" || itm.length === 0) {
			itm = "";
		}
		i += 1;
	}
	if (itm === first) {
		return;
	}

	// Determine the sort type. You can set numeric=true on the header to force numeric sorting
	sortfn = ts_sort_caseinsensitive;
	if (thead) {
		if (itm.match(/-?\d+(?:\.\d+)?/)) {
			sortfn = ts_sort_numeric; // Normal number
		}
		numeric_flag = t.tHead.rows[0].cells[column].getAttribute("numeric");
		if (numeric_flag === "true") {
			sortfn = ts_sort_numeric;
		}
	}

	// Delete any other arrows there may be showing
	all_sort_links = $$("a.sortheader.sort");
	for (ci = 0; ci < all_sort_links.length; ci += 1) {
		if (getParent(all_sort_links[ci], "table") === getParent(lnk, "table")) { // in the same table as us?
			all_sort_links[ci].className = all_sort_links[ci].className.replace(" desc", "").replace(" asc", "");
		}
	}

	// Do the sorting
	SORT_COLUMN_INDEX = column;
	firstRow = [];
	newRows = [];
	for (k = 0; k < t.tBodies.length; k += 1) {
		for (i = 0; i < t.tBodies[k].rows[0].length; i += 1) {
			firstRow[i] = t.tBodies[k].rows[0][i];
		}
	}
	for (k = 0; k < t.tBodies.length; k += 1) {
		if (!thead) {
			// Skip the first row
			for (j = 1; j < t.tBodies[k].rows.length; j += 1) {
				newRows[j - 1] = t.tBodies[k].rows[j];
			}
		} else {
			// Do NOT skip the first row
			for (j = 0; j < t.tBodies[k].rows.length; j += 1) {
				newRows[j] = t.tBodies[k].rows[j];
			}
		}
	}
	newRows.sort(sortfn);
	if (lnk.getAttribute("sortdir") === 'down') {
		lnk.setAttribute('sortdir', 'up');
		lnk.className += " asc";
	} else {
		newRows.reverse();
		lnk.setAttribute('sortdir', 'down');
		lnk.className += " desc";
	}
    // We appendChild rows that already exist to the tbody, so it moves them rather than creating new ones
    // don't do sortbottom rows
    for (i = 0; i < newRows.length; i += 1) {
		if (!newRows[i].className || (newRows[i].className && (newRows[i].className.indexOf('sortbottom') === -1))) {
			t.tBodies[0].appendChild(newRows[i]);
		}
	}
    // do sortbottom rows only
    for (i = 0; i < newRows.length; i += 1) {
		if (newRows[i].className && (newRows[i].className.indexOf('sortbottom') !== -1)) {
			t.tBodies[0].appendChild(newRows[i]);
		}
	}
	alternate(t);
}

function addEvent(elm, evType, fn, useCapture)
// addEvent and removeEvent
// cross-browser event handling for IE5+,	NS6 and Mozilla
// By Scott Andrew
{
	if (elm.addEventListener) {
		elm.addEventListener(evType, fn, useCapture);
		return true;
	} else if (elm.attachEvent) {
		var r = elm.attachEvent("on" + evType, fn);
		return r;
	} else {
		alert("Handler could not be removed");
	}
}

function clean_num(str) {
	str = str.replace(/^[^\-?\d]+/, "");
	str.replace(/(\d),(\d)/g, "$1$2");
	return str;
}
