var NS4 = (navigator.appName == "Netscape" && parseInt(navigator.appVersion) < 5);

function addOption(theSel, theText, theValue)
{
  var newOpt = new Option(theText, theValue);
  var selLength = theSel.length;
  theSel.options[selLength] = newOpt;
}

function swapOptions(theSel, index1, index2)
{
	var text, value;
  text = theSel.options[index1].text;
  value = theSel.options[index1].value;
  theSel.options[index1].text = theSel.options[index2].text;
  theSel.options[index1].value = theSel.options[index2].value;
  theSel.options[index2].text = text;
  theSel.options[index2].value = value;
}

function deleteOption(theSel, theIndex)
{ 
  var selLength = theSel.length;
  if(selLength>0)
  {
    theSel.options[theIndex] = null;
  }
}

function moveOptions(theSelFrom, theSelTo)
{
  
  var selLength = theSelFrom.length;
  var selectedText = new Array();
  var selectedValues = new Array();
  var selectedCount = 0;
  
  var i;
  
  for(i=selLength-1; i>=0; i--)
  {
    if(theSelFrom.options[i].selected)
    {
      selectedText[selectedCount] = theSelFrom.options[i].text;
      selectedValues[selectedCount] = theSelFrom.options[i].value;
      deleteOption(theSelFrom, i);
      selectedCount++;
    }
  }
  
  for(i=selectedCount-1; i>=0; i--)
  {
    addOption(theSelTo, selectedText[i], selectedValues[i]);
  }
  
  if(NS4) history.go(0);
}

function moveOptionUp(theSel) {
	var index = theSel.selectedIndex;
	if (index > 0) {
		swapOptions(theSel, index-1, index);
  	theSel.selectedIndex = index-1;
	}
}

function moveOptionDown(theSel) {
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

