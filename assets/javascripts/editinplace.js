function getCurrencyValue(str) {
  var result = str.match(/^(([0-9]+[.,])+[0-9]+) (.+)/);
  return new Array(result[1], result[3]);
}

function makeEditable(id, name){
  var obj = $(id)
  
  Event.observe(id, 'click', function(){edit_and_focus(obj, name)}, false);
  Event.observe(id, 'mouseover', function(){showAsEditable(obj)}, false);
  Event.observe(id, 'mouseout', function(){showAsEditable(obj, true)}, false);
}

function edit_and_focus(obj, name) {
  edit(obj, name);
  
  Form.Element.focus(obj.id+'_edit');
  Form.Element.select(obj.id+'_edit');
}

function edit(obj, name, obj_value) {
  Element.hide(obj);
  
  var obj_value = typeof(obj_value) != 'undefined' ? obj_value : obj.innerHTML;
  var parsed = getCurrencyValue(obj_value);
  var value = parsed[0];
  var currency = parsed[1]
  
  
  var button = '<span id="'+obj.id+'_editor"><input id="'+obj.id+'_cancel" type="image" src="/images/cancel.png" value="CANCEL" /> ';
  var text = '<input id="'+obj.id+'_edit" name="'+name+'" size="7" value="'+value+'" class="currency"/> '+currency+'</span>';
  
  new Insertion.After(obj, button+text);

  Event.observe(obj.id+'_cancel', 'click', function(){cleanUp(obj)}, false);
}

function showAsEditable(obj, clear){
  if (!clear){
    Element.addClassName(obj, 'editable');
  }else{
    Element.removeClassName(obj, 'editable');
  }
}

function cleanUp(obj, keepEditable){
  Element.remove(obj.id+'_editor');
  Element.show(obj);
  if (!keepEditable) showAsEditable(obj, true);
}
