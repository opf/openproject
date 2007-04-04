//*****************************************************************************
// Do not remove this notice.
//
// Copyright 2000-2004 by Mike Hall.
// See http://www.brainjar.com for terms of use.
//*****************************************************************************

//----------------------------------------------------------------------------
// Emulation de la fonction push pour IE5.0
//----------------------------------------------------------------------------
if(!Array.prototype.push){Array.prototype.push=function(){for(var i=0;i<arguments.length;i++)this[this.length]=arguments[i];};};

//----------------------------------------------------------------------------
// Code to determine the browser and version.
//----------------------------------------------------------------------------

function Browser() {

  var ua, s, i;

  this.isIE    = false;  // Internet Explorer
  this.isOP    = false;  // Opera
  this.isNS    = false;  // Netscape
  this.version = null;
  //-- debut ajout ci ----
  this.isIE5mac    = false;  // Internet Explorer 5 mac
  //-- fin ajout ci ----    

  ua = navigator.userAgent;

  //-- debut ajout ci ----
  if (ua.indexOf("Opera")==-1 && ua.indexOf("MSIE 5")>-1 && ua.indexOf("Mac")>-1) {
    this.isIE5mac = true;
    this.version = "";
    return;
  }
  //-- fin ajout ci ----    
  
  s = "Opera";
  if ((i = ua.indexOf(s)) >= 0) {
    this.isOP = true;
    this.version = parseFloat(ua.substr(i + s.length));
    return;
  }

  s = "Netscape6/";
  if ((i = ua.indexOf(s)) >= 0) {
    this.isNS = true;
    this.version = parseFloat(ua.substr(i + s.length));
    return;
  }

  // Treat any other "Gecko" browser as Netscape 6.1.

  s = "Gecko";
  if ((i = ua.indexOf(s)) >= 0) {
    this.isNS = true;
    this.version = 6.1;
    return;
  }
  
  s = "MSIE";
  if ((i = ua.indexOf(s))) {
    this.isIE = true;
    this.version = parseFloat(ua.substr(i + s.length));
    return;
  }
}

var browser = new Browser();

//----------------------------------------------------------------------------
// Code for handling the menu bar and active button.
//----------------------------------------------------------------------------

var activeButton = null;


function buttonClick(event, menuId) {

  var button;

  // Get the target button element.

  if (browser.isIE)
    button = window.event.srcElement;
  else
    button = event.currentTarget;

  // Blur focus from the link to remove that annoying outline.

  button.blur();

  // Associate the named menu to this button if not already done.
  // Additionally, initialize menu display.

  if (button.menu == null) {
    button.menu = document.getElementById(menuId);
    if (button.menu.isInitialized == null)
      menuInit(button.menu);
  }

  // Set mouseout event handler for the button, if not already done.

  if (button.onmouseout == null)
    button.onmouseout = buttonOrMenuMouseout;

  // Exit if this button is the currently active one.

  if (button == activeButton)
    return false;

  // Reset the currently active button, if any.

  if (activeButton != null)
    resetButton(activeButton);

  // Activate this button, unless it was the currently active one.

  if (button != activeButton) {
    depressButton(button);
    activeButton = button;
  }
  else
    activeButton = null;

  return false;
}

function buttonMouseover(event, menuId) {

  var button;
//-- debut ajout ci ----
  if (!browser.isIE5mac) { 
  //-- fin ajout ci ----
  
//-- debut ajout ci ----
	cicacheselect();
//-- fin ajout ci ----    

  // Activates this button's menu if no other is currently active.

  if (activeButton == null) {
    buttonClick(event, menuId);
    return;
  }

  // Find the target button element.

  if (browser.isIE)
    button = window.event.srcElement;
  else
    button = event.currentTarget;

  // If any other button menu is active, make this one active instead.

  if (activeButton != null && activeButton != button)
    buttonClick(event, menuId);
 //-- debut ajout ci ----
  } 
  //-- fin ajout ci ----
    
}

function depressButton(button) {

  var x, y;

  // Update the button's style class to make it look like it's
  // depressed.

  button.className += " menuButtonActive";

  // Set mouseout event handler for the button, if not already done.

  if (button.onmouseout == null)
    button.onmouseout = buttonOrMenuMouseout;
  if (button.menu.onmouseout == null)
    button.menu.onmouseout = buttonOrMenuMouseout;

  // Position the associated drop down menu under the button and
  // show it.

  x = getPageOffsetLeft(button);
  y = getPageOffsetTop(button) + button.offsetHeight - 1;

  // For IE, adjust position.

  if (browser.isIE) {
    x += button.offsetParent.clientLeft;
    y += button.offsetParent.clientTop;
  }

  button.menu.style.left = x + "px";
  button.menu.style.top  = y + "px";0
  button.menu.style.visibility = "visible";
}

function resetButton(button) {

  // Restore the button's style class.

  removeClassName(button, "menuButtonActive");

  // Hide the button's menu, first closing any sub menus.

  if (button.menu != null) {
    closeSubMenu(button.menu);
    button.menu.style.visibility = "hidden";
  }
}

//----------------------------------------------------------------------------
// Code to handle the menus and sub menus.
//----------------------------------------------------------------------------

function menuMouseover(event) {

  var menu;
 //-- debut ajout ci ----
  if (!browser.isIE5mac) { 
  //-- fin ajout ci ----
//-- debut ajout ci ----
	cicacheselect();
//-- fin ajout ci ----    

  // Find the target menu element.
  if (browser.isIE)
    menu = getContainerWith(window.event.srcElement, "DIV", "menu");
  else
    menu = event.currentTarget;

  // Close any active sub menu.

  if (menu.activeItem != null)
    closeSubMenu(menu);
 //-- debut ajout ci ----
  } 
  //-- fin ajout ci ----
}

function menuItemMouseover(event, menuId) {

  var item, menu, x, y;
//-- debut ajout ci ----
	cicacheselect();
//-- fin ajout ci ----    

  // Find the target item element and its parent menu element.

  if (browser.isIE)
    item = getContainerWith(window.event.srcElement, "A", "menuItem");
  else
    item = event.currentTarget;
  menu = getContainerWith(item, "DIV", "menu");

  // Close any active sub menu and mark this one as active.

  if (menu.activeItem != null)
    closeSubMenu(menu);
  menu.activeItem = item;

  // Highlight the item element.

  item.className += " menuItemHighlight";

  // Initialize the sub menu, if not already done.

  if (item.subMenu == null) {
    item.subMenu = document.getElementById(menuId);
    if (item.subMenu.isInitialized == null)
      menuInit(item.subMenu);
  }

  // Set mouseout event handler for the sub menu, if not already done.

  if (item.subMenu.onmouseout == null)
    item.subMenu.onmouseout = buttonOrMenuMouseout;

  // Get position for submenu based on the menu item.

  x = getPageOffsetLeft(item) + item.offsetWidth;
  y = getPageOffsetTop(item);

  // Adjust position to fit in view.

  var maxX, maxY;

  if (browser.isIE) {
    maxX = Math.max(document.documentElement.scrollLeft, document.body.scrollLeft) +
      (document.documentElement.clientWidth != 0 ? document.documentElement.clientWidth : document.body.clientWidth);
    maxY = Math.max(document.documentElement.scrollTop, document.body.scrollTop) +
      (document.documentElement.clientHeight != 0 ? document.documentElement.clientHeight : document.body.clientHeight);
  }
  if (browser.isOP) {
    maxX = document.documentElement.scrollLeft + window.innerWidth;
    maxY = document.documentElement.scrollTop  + window.innerHeight;
  }
  if (browser.isNS) {
    maxX = window.scrollX + window.innerWidth;
    maxY = window.scrollY + window.innerHeight;
  }
  maxX -= item.subMenu.offsetWidth;
  maxY -= item.subMenu.offsetHeight;

  if (x > maxX)
    x = Math.max(0, x - item.offsetWidth - item.subMenu.offsetWidth
      + (menu.offsetWidth - item.offsetWidth));
  y = Math.max(0, Math.min(y, maxY));

  // Position and show the sub menu.

  item.subMenu.style.left = x + "px";
  item.subMenu.style.top  = y + "px";
  item.subMenu.style.visibility = "visible";

  // Stop the event from bubbling.

  if (browser.isIE)
    window.event.cancelBubble = true;
  else
    event.stopPropagation();
}

function closeSubMenu(menu) {

  if (menu == null || menu.activeItem == null)
    return;

  // Recursively close any sub menus.

  if (menu.activeItem.subMenu != null) {
    closeSubMenu(menu.activeItem.subMenu);
    menu.activeItem.subMenu.style.visibility = "hidden";
    menu.activeItem.subMenu = null;
  }
  removeClassName(menu.activeItem, "menuItemHighlight");
  menu.activeItem = null;
}


function buttonOrMenuMouseout(event) {

  var el;

  // If there is no active button, exit.

  if (activeButton == null)
    return;

  // Find the element the mouse is moving to.

  if (browser.isIE)
    el = window.event.toElement;
  else if (event.relatedTarget != null)
      el = (event.relatedTarget.tagName ? event.relatedTarget : event.relatedTarget.parentNode);

  // If the element is not part of a menu, reset the active button.

  if (getContainerWith(el, "DIV", "menu") == null) {
    resetButton(activeButton);
    activeButton = null;
//-- debut ajout ci ----
	cimontreselect();
//-- fin ajout ci ----    
  }
}


//----------------------------------------------------------------------------
// Code to initialize menus.
//----------------------------------------------------------------------------

function menuInit(menu) {

  var itemList, spanList;
  var textEl, arrowEl;
  var itemWidth;
  var w, dw;
  var i, j;

  // For IE, replace arrow characters.

  if (browser.isIE) {
    menu.style.lineHeight = "2.5ex";
    spanList = menu.getElementsByTagName("SPAN");
    for (i = 0; i < spanList.length; i++)
      if (hasClassName(spanList[i], "menuItemArrow")) {
        spanList[i].style.fontFamily = "Webdings";
        spanList[i].firstChild.nodeValue = "4";
      }
  }

  // Find the width of a menu item.

  itemList = menu.getElementsByTagName("A");
  if (itemList.length > 0)
    itemWidth = itemList[0].offsetWidth;
  else
    return;

  // For items with arrows, add padding to item text to make the
  // arrows flush right.

  for (i = 0; i < itemList.length; i++) {
    spanList = itemList[i].getElementsByTagName("SPAN");
    textEl  = null;
    arrowEl = null;
    for (j = 0; j < spanList.length; j++) {
      if (hasClassName(spanList[j], "menuItemText"))
        textEl = spanList[j];
      if (hasClassName(spanList[j], "menuItemArrow"))
        arrowEl = spanList[j];
    }
    if (textEl != null && arrowEl != null) {
      textEl.style.paddingRight = (itemWidth 
        - (textEl.offsetWidth + arrowEl.offsetWidth)) + "px";
      // For Opera, remove the negative right margin to fix a display bug.
      if (browser.isOP)
        arrowEl.style.marginRight = "0px";
    }
  }

  // Fix IE hover problem by setting an explicit width on first item of
  // the menu.

  if (browser.isIE) {
    w = itemList[0].offsetWidth;
    itemList[0].style.width = w + "px";
    dw = itemList[0].offsetWidth - w;
    w -= dw;
    itemList[0].style.width = w + "px";
  }

  // Mark menu as initialized.

  menu.isInitialized = true;
}

//----------------------------------------------------------------------------
// General utility functions.
//----------------------------------------------------------------------------

function getContainerWith(node, tagName, className) {

  // Starting with the given node, find the nearest containing element
  // with the specified tag name and style class.

  while (node != null) {
    if (node.tagName != null && node.tagName == tagName &&
        hasClassName(node, className))
      return node;
    node = node.parentNode;
  }

  return node;
}

function hasClassName(el, name) {

  var i, list;

  // Return true if the given element currently has the given class
  // name.

  list = el.className.split(" ");
  for (i = 0; i < list.length; i++)
    if (list[i] == name)
      return true;

  return false;
}

function removeClassName(el, name) {

  var i, curList, newList;

  if (el.className == null)
    return;

  // Remove the given class name from the element's className property.

  newList = new Array();
  curList = el.className.split(" ");
  for (i = 0; i < curList.length; i++)
    if (curList[i] != name)
      newList.push(curList[i]);
  el.className = newList.join(" ");
}

function getPageOffsetLeft(el) {

  var x;

  // Return the x coordinate of an element relative to the page.

  x = el.offsetLeft;
  if (el.offsetParent != null)
    x += getPageOffsetLeft(el.offsetParent);

  return x;
}

function getPageOffsetTop(el) {

  var y;

  // Return the x coordinate of an element relative to the page.

  y = el.offsetTop;
  if (el.offsetParent != null)
    y += getPageOffsetTop(el.offsetParent);

  return y;
}

//-- debut ajout ci ----
function cicacheselect(){
  if (browser.isIE) {
	 oSelects = document.getElementsByTagName('SELECT');
	 if (oSelects.length > 0) {
	  for (i = 0; i < oSelects.length; i++) {
	   oSlt = oSelects[i];
	    if (oSlt.style.visibility != 'hidden') {oSlt.style.visibility = 'hidden';}
	  }
	 }  
	 oSelects = document.getElementsByName('masquable');
	 if (oSelects.length > 0) {
	  for (i = 0; i < oSelects.length; i++) {
	   oSlt = oSelects[i];
	    if (oSlt.style.visibility != 'hidden') {oSlt.style.visibility = 'hidden';}
	  }
	 }  
  }
}	

function cimontreselect(){
  if (browser.isIE) {
	 oSelects = document.getElementsByTagName('SELECT');
	 if (oSelects.length > 0) {
	  for (i = 0; i < oSelects.length; i++) {
	   oSlt = oSelects[i];
	    if (oSlt.style.visibility != 'visible') {oSlt.style.visibility = 'visible';}
	  }
	 }  
	 oSelects = document.getElementsByName('masquable');
	 if (oSelects.length > 0) {
	  for (i = 0; i < oSelects.length; i++) {
	   oSlt = oSelects[i];
	    if (oSlt.style.visibility != 'visible') {oSlt.style.visibility = 'visible';}
	  }
	 }  
  }
}	

//-- fin ajout ci ----    
