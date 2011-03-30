/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, selectAllOptions, moveOptions, moveOptionUp, moveOptionDown */

Reporting.GroupBys = {
  group_by_container_ids: function() {
    return $w('group_by_columns group_by_rows');
  },

  sortable_options: function() {
    return {
      tag: 'span',
      only: "drag_element",
      overlap: 'horizontal',
      constraint:'horizontal',
      containment: Reporting.GroupBys.group_by_container_ids(),
      dropOnEmpty: true,
      hoverclass: 'drag_container_accept'
    };
  },

  recreate_sortables: function() {
    Reporting.GroupBys.group_by_container_ids().each(function(id) {
      Sortable.create(id, Reporting.GroupBys.sortable_options());
    });
  },

  initialize_drag_and_drop_areas: function() {
    Reporting.GroupBys.recreate_sortables();
  },

  create_label: function(group_by, text) {
    return new Element('label', {
      'class': 'in_row group_by_label',
      'for': group_by.identify(),
      'id': group_by.identify() + '_label'
    }).update(text);
  },

  create_remove_button: function(group_by) {
    var button = new Element('span', {
      'class': 'group_by_remove in_row',
      'id': group_by.identify() + '_remove'
    });
    Reporting.GroupBys.remove_button_hover(button, false);
    button.observe('mouseover', function() { Reporting.GroupBys.remove_button_hover(this, true); });
    button.observe('mouseout',  function() { Reporting.GroupBys.remove_button_hover(this, false); });
    button.observe('mousedown', function() { Reporting.GroupBys.remove_group_by(button.up('.group_by_element')) });
    return button;
  },

  create_arrow: function(group_by, position) {
    return new Element('span', {
      'class': 'arrow in_row arrow_' + position,
      'id': group_by.identify() + '_arrow_' + position
    });
  },

  create_group_by: function(field, caption) {
    var group_by, label, right_arrow, left_arrow, remove_button;
    group_by = new Element('span', {
      'class': 'in_row drag_element group_by_element',
      'data-group-by': field
    });
    group_by.identify(); // give it a unique id
    
    left_arrow = Reporting.GroupBys.create_arrow(group_by, 'left');
    group_by.appendChild(left_arrow);
    
    label = Reporting.GroupBys.create_label(group_by, caption);
    Reporting.GroupBys.init_group_by_hover_effects([group_by, label]);
    group_by.appendChild(label);
    
    remove_button = Reporting.GroupBys.create_remove_button(group_by);
    group_by.appendChild(remove_button);
    
    right_arrow = Reporting.GroupBys.create_arrow(group_by, 'right');
    group_by.appendChild(right_arrow);
    return group_by;
  },

  // on mouse_over of a group_by or it's label, change the color of the group_by
  // also change the color of the arrows
  init_group_by_hover_effects: function(elements) {
    elements.each(function(element) {
      ['mouseover', 'mouseout'].each(function(event_type) {
        element.observe(event_type, function(event) {
          Reporting.GroupBys.group_by_hover_effect(event, event_type == 'mouseover');
        });
      });
    });
  },

  group_by_hover_effect: function(event, do_hover) {
    var group_by = $(Event.element(event));
    // we possibly hit a tag inside the group_by, so go search the group_by then
    if (!group_by.hasClassName('group_by_element')) {
      group_by = group_by.up('.group_by_element');
    }
    if (group_by !== null) {
      Reporting.GroupBys.group_by_hover(group_by, do_hover);
    }
  },

  group_by_hover: function(group_by, state) {
    if (state) {
      group_by.childElements().each(function(e) { e.addClassName('hover'); });
    } else {
      group_by.childElements().each(function(e) { e.removeClassName('hover'); });
    }
  },

  // This is whether it is possible to add a new group if <<field>> through the
  // add-group-by select-box or not.
  adding_group_by_enabled: function(field, state) {
    $w('add_group_by_columns add_group_by_rows').each(function(container_id) {
      Reporting.Filters.select_option_enabled($(container_id), field, state);
    });
  },

 remove_button_hover: function(button, status) {
    if (status) {
      $(button).update('✖');
    }
    else {
      $(button).update('⤫');
    }
  },

  remove_group_by: function(group_by) {
    Reporting.GroupBys.adding_group_by_enabled(group_by.readAttribute('data-group-by'), true);
    group_by.remove();
  },

  add_group_by_from_select: function(select) {
    var field, caption, container, selected_option;
    field = $(select).getValue();
    container = select.up('.drag_container');
    selected_option = select.select("[value='" + field + "']").first();
    caption = selected_option.readAttribute('data-label');
    Reporting.GroupBys.add_group_by(field, caption, container);
    select.select("[value='']").first().selected = true;
  },

  add_group_by: function(field, caption, container) {
    var group_by, add_groups_select_box;
    add_groups_select_box = container.select('select').first();
    group_by = Reporting.GroupBys.create_group_by(field, caption);
    add_groups_select_box.insert({ before: group_by });
    Reporting.GroupBys.adding_group_by_enabled(field, false);
    Reporting.GroupBys.recreate_sortables();
  }
};

Reporting.onload(function () {
  Reporting.GroupBys.initialize_drag_and_drop_areas();
  $('add_group_by_rows').observe("change", function () {
    Reporting.GroupBys.add_group_by_from_select(this);
  });
  $('add_group_by_columns').observe("change", function () {
    Reporting.GroupBys.add_group_by_from_select(this);
  });
});
