var NS4 = (navigator.appName == "Netscape" && parseInt(navigator.appVersion) < 5);

function createOption(theText, theValue, theCategory) {
  var newOpt = document.createElement('option');
  newOpt.text = theText;
  newOpt.value = theValue;
  newOpt.setAttribute("data-category", theCategory);
  return newOpt;
}

function addOption(theSel, newOpt, theCategory)
{
  var theCategory = newOpt.getAttribute("data-category");
  theSel = $(theSel);
  if (theCategory && (theSel.childElements().length > 0) && theSel.down(0).tagName == "OPTGROUP") { // add the opt to the given category
    opt_groups = theSel.childElements();
    for (var i=0; i<opt_groups.length; i++)
      if (opt_groups[i].getAttribute("data-category") == theCategory) {
        opt_groups[i].appendChild(newOpt);
        break;
      }
  }
  else { // no category given, just add the opt to the end of the select list
    theSel.appendChild(newOpt);
  }
}

function swapOptions(theSel, index1, index2)
{
  theSel = $(theSel);
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
  theSel = $(theSel);
  var selLength = theSel.length;
  if(selLength>0)
  {
    theSel.options[theIndex] = null;
  }
}

function moveOptions(theSelFrom, theSelTo)
{
  theSelFrom = $(theSelFrom);
  theSelTo = $(theSelTo);
  var selLength = theSelFrom.length;
  var selectedText = new Array();
  var selectedValues = new Array();
  var selectedCategories = new Array();
  var selectedCount = 0;

  var i;

  for(i=selLength-1; i>=0; i--)
    if(theSelFrom.options[i].selected)
    {
      addOption(theSelTo, theSelFrom.options[i].cloneNode(true));
      deleteOption(theSelFrom, i);
    }

  if(has_optgroups(theSelTo)) sortOptions(theSelTo);
  if(NS4) history.go(0);
}

function moveOptionUp(theSel) {
  theSel = $(theSel);
  var index = theSel.selectedIndex;
  if (index > 0) {
    swapOptions(theSel, index-1, index);
    theSel.selectedIndex = index-1;
  }
}

function moveOptionDown(theSel) {
  theSel = $(theSel);
  var index = theSel.selectedIndex;
  if (index < theSel.length - 1) {
    swapOptions(theSel, index, index+1);
    theSel.selectedIndex = index+1;
  }
}

function selectAllOptions(select) {
  select = $(select);
  for (var i=0; i<select.options.length; i++) {
    select.options[i].selected = true;
  }
}

// Returns true if the given select-box has optgroups
// We assume that a possibly present optgroup is the first child element of the select-box.
function has_optgroups(theSel) {
  theSel = $(theSel);
  groups = theSel.select('optgroup');
  return (groups.size() > 0);
}

// Returns true if the given select-box has optgroups and at least one of those contains a child
// We assume that a possibly present optgroup is the first child element of the select-box.
function filled_optgroups(theSel) {
  if (!has_optgroups(theSel)) return false;
  groups = theSel.select('optgroup');
  hit = false;
  for (var i = 0; i < groups.length; i++) {
    if (groups[i].childElements().size() > 0) {
      hit = true;
      break;
    }
  }
  return hit;
}


// Compares two option elements (return -1 if a < b, if not return 1).
// If those elements have a 'data-sort_by' attribute, we compare that attribute.
// If this is not the case we just compare their labels.
function compareOptions(a,b) {
  var a_cmp, b_cmp;
  a_cmp = a.getAttribute("data-sort_by") ? a.getAttribute("data-sort_by") : a.text.toLowerCase();
  b_cmp = b.getAttribute("data-sort_by") ? b.getAttribute("data-sort_by") : b.text.toLowerCase();
  return (a_cmp < b_cmp ) ? -1 : 1;
}

// Sorts all elements of the given select-box.
// If that select-box contains optgroups, the options are sorted for each optgroup separately.
function sortOptions(theSel) {
  theSel = $(theSel);
  if (filled_optgroups(theSel)) {
    // handle each optgroup separately
    theSel.childElements().each(function(group){
      var sorted_elements;
      // get all elements of this optgroup and sort them
      sorted_elements = $A(group.childElements()).sort(compareOptions);
      // make optgroup empty
      $A(group.childElements()).each(function(o){$(o).remove()});
      // insert sorted elements into opgroup
      sorted_elements.each(function(o){
        $(group).insert({'bottom' : o});
      });
    });
  }
  // there is no optgroup so just sort the options
  $A(theSel.options).sort(compareOptions).each(function(o,i) {
    theSel.options[i] = o;
  });
}

// Clears any filled optgroup and puts those Elements to the Select Box Toplevel.
// A Backreference to the previous optgroups' label is held in the attribute 'data-optgroup'.
// Note that any Optgroups will still be present after moving the options
function moveOptionsToTopLevel(theSel) {
  if (!(filled_optgroups(theSel))) return;
  theSel.childElements().each(function(group) {
    $A(group.childElements()).each(function(o) {
      tmp = o;
      o.remove();
      $(theSel).insert({'bottom' : tmp});
      tmp.setAttribute('data-optgroup', group.getAttribute('label'))
    });
  });
}

// Moves any options in the Select Box to the optgroup with a label that equals the options'
// 'data-optgroup' field. That is reset after moving the respective option.
// Note that the Optgroup has to be present before calling this function, as it will not be
// created in the process
function putOptionsIntoOpgroups(theSel) {
  if (!has_optgroups(theSel)) return;
  groups = theSel.select('optgroup');
  theSel.select('option').each(function (option) {
    for (var i = 0; i < groups.length; i++) {
      if (option.getAttribute('data-optgroup') == groups[i].getAttribute('label')) {
        tmp = option;
        option.remove();
        groups[i].insert({'bottom' : tmp});
        tmp.setAttribute('data-optgroup', '');
      }
    }
  });
}
