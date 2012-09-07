jQuery(document).ready(function(){
  var clone = jQuery('.action_menu_main').clone();
  jQuery('#lower-title-bar').append(clone);
  clone.onClickDropDown();
});
