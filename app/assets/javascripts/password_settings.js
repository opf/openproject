function disable_password_fields(){
  $('user_password').disable();
  $('user_password_confirmation').disable();
}

function enable_password_fields(){
  $('user_password').enable();
  $('user_password_confirmation').enable();
}

function toggle_password_fields(){
  if( $('set_random_password').getValue() == "1" ){
    disable_password_fields();
  }
  else{
    enable_password_fields();
  }
}

function move_password_options_div(){
  pod = $('password_options').remove();
  $('password_fields').insert(pod.immediateDescendants()[0]);
  $('password_fields').insert(pod.immediateDescendants()[0]);
}

function init(){
  move_password_options_div();
  $('set_random_password').observe('click', toggle_password_fields);
  toggle_password_fields();
}

document.observe("dom:loaded", init);