// Work packages page
// Select work package menu item when filters are cleared
var resetSelectedMenuItem = function() {
  jQuery('#menu-sidebar .selected').removeClass('selected');
  jQuery('#menu-sidebar .work-packages').addClass('selected');
}

var initQuerySelectBehaviour = function() {
  if(!OpenProject.Helpers.accessibilityModeEnabled()) {
    jQuery('#query-select').select2()
  }

  jQuery('#query-select').change(function() {
    document.location.href = window.location.pathname + '?query_id=' + this.value;
    // TODO use FilterQueryStringBuilder
  });
}

jQuery(document).ready(initQuerySelectBehaviour);
