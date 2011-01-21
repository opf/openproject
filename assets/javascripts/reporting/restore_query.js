/*
jslint Reporting: false, nomen: true, debug: false, evil: false,
    onevar: false, browser: true, white: false, indent: 0
*/
var Reporting.RestoreQueries = {};

Reporting.RestoreQueries.set_filters = function() {
  <% sorted_filters = engine::Filter.all.map {|fclass| query.filters.detect {|f| f.class == fclass } }.compact %>
  <% visible_filters = sorted_filters.select {|f| f.class.display? } %>
  <% visible_filters.each do |f| %>
    restore_filter("<%= f.class.underscore_name %>",
                   "<%= f.operator.to_s %>"<%= "," if f.values %>
                    <%= f.values.to_json.html_safe if f.values  %>);
    <% if f.class.has_dependents? %>
      // Evaluate the dependency observer synchronously. See _multi_values_with_dependent.rhtml for more info
      <%= "observe_selector_#{f.class.underscore_name}(true);" %>
    <% end %>
  <% end %>
}

Reporting.RestoreQueries.set_group_bys = function() {
  // Activate recent group_bys on loading
  group_bys = $('group_by_container').childElements().collect(function(og) {
    return $(og).childElements();
  }).flatten().select(function(group_by) {
    return $(group_by).hasAttribute("data-selected-axis");
  }).sortBy(function(group_by) {
    return $(group_by).getAttribute("data-selected-index");
  }).each(function(group_by) {
    var axis = $(group_by).getAttribute("data-selected-axis");
    var name = $(group_by).getAttribute("value");
    show_group_by(axis, name);
  });
}

Reporting.RestoreQueries.restore_query_inputs = function() {
  disable_all_filters();
  disable_all_group_bys();
  set_filters();
  set_group_bys();
}

Reporting.RestoreQueries.restore_query_inputs();
