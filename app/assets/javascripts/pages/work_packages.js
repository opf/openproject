// Work packages page
// Select work package menu item when filters are cleared
var resetSelectedMenuItem = function() {
  jQuery('#menu-sidebar .selected').removeClass('selected');
  jQuery('#menu-sidebar .work-packages').addClass('selected');
}
