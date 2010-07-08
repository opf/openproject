var NS4 = (navigator.appName == "Netscape" && parseInt(navigator.appVersion) < 5);

function addOption(theSel, theText, theValue, theCategory)
{
  theSel = $(theSel.id);
  var newOpt = new Option(theText, theValue);
  newOpt.setAttribute("data-category", theCategory);
  if (theCategory && (theSel.childElements().length > 0) && theSel.down(0).tagName == "OPTGROUP") { // add the opt to the given category
    opt_groups = theSel.childElements();
    for (i in opt_groups)
    if (opt_groups[i].getAttribute("data-category") == theCategory) {
      opt_groups[i].appendChild(newOpt);
      break;
    }
  }
  else { // no category given, just add the opt to the end of the select list
    var selLength = theSel.length;
    theSel.options[selLength] = newOpt;
  }
}

function swapOptions(theSel, index1, index2) //FIXME: add category support
{
  theSel = $(theSel.id);
  var text, value;
  text = theSel.options[index1].text;
  value = theSel.options[index1].value;
  category = theSel.options[index1].getAttribute("data-category");
  theSel.options[index1].text = theSel.options[index2].text;
  theSel.options[index1].value = theSel.options[index2].value;
  theSel.options[index1].setAttribute("data-category", theSel.options[index2].getAttribute("data-category"));
  theSel.options[index2].text = text;
  theSel.options[index2].value = value;
  theSel.options[index2].setAttribute("data-category", category);
}

function deleteOption(theSel, theIndex)
{
  theSel = $(theSel.id);
  var selLength = theSel.length;
  if(selLength>0)
  {
    theSel.options[theIndex] = null;
  }
}

function moveOptions(theSelFrom, theSelTo)
{
  theSelFrom = $(theSelFrom.id);
  theSelTo = $(theSelTo.id);
  var selLength = theSelFrom.length;
  var selectedText = new Array();
  var selectedValues = new Array();
  var selectedCategories = new Array();
  var selectedCount = 0;

  var i;

  for(i=selLength-1; i>=0; i--)
  {
    if(theSelFrom.options[i].selected)
    {
      selectedText[selectedCount] = theSelFrom.options[i].text;
      selectedValues[selectedCount] = theSelFrom.options[i].value;
      selectedCategories[selectedCount] = theSelFrom.options[i].getAttribute("data-category");
      deleteOption(theSelFrom, i);
      selectedCount++;
    }
  }

  for(i=selectedCount-1; i>=0; i--)
  {
    addOption(theSelTo, selectedText[i], selectedValues[i], selectedCategories[i]);
  }

  if(NS4) history.go(0);
}

function moveOptionUp(theSel) {
  theSel = $(theSel.id);
  var index = theSel.selectedIndex;
  if (index > 0) {
    swapOptions(theSel, index-1, index);
    theSel.selectedIndex = index-1;
  }
}

function moveOptionDown(theSel) {
  theSel = $(theSel.id);
  var index = theSel.selectedIndex;
  if (index < theSel.length - 1) {
    swapOptions(theSel, index, index+1);
    theSel.selectedIndex = index+1;
  }
}

function selectAllOptions(id)
{
  var select = $(id);
  for (var i=0; i<select.options.length; i++) {
    select.options[i].selected = true;
  }
}

