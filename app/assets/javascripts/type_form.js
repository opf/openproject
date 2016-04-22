jQuery(document).ready(function($) {
  jQuery("[id^=type_attribute_visibility_default]").change(function() {
    var active = jQuery(this);
    var alwaysId = active.attr("id").replace(/_default_/, "_visible_");
    var always = jQuery("#" + alwaysId);

    always.prop('disabled', !this.checked);
  });
});
