/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, selectAllOptions, moveOptions, moveOptionUp, moveOptionDown */

Reporting.GroupBys = {
  attach_move_button: function (direction) {
    var btn = $$(".buttons.group_by.move.move" + direction)[0];

    var axis;
    if (direction === "Up" || direction === "Down") {
      axis = "columns";
    } else if (direction === "Left" || direction === "Right") {
      axis = "rows";
    }

    var selected_container = $(btn.form).select("#group_by_" + axis)[0];
    var group_by_container = btn.form.group_by_container;

    var source_container, target_container;
    if (direction === "Down" || direction === "Right") {
      source_container = selected_container;
      target_container = group_by_container;
    } else if (direction === "Up" || direction === "Left") {
      target_container = selected_container;
      source_container = group_by_container;
    }

    btn.observe("click", function () {
      moveOptions(source_container, target_container);
    });
  },

  attach_sort_button: function (direction, axis) {
    var btn = $$(".buttons.group_by.sort.sort" + direction + ".sort-" + axis)[0];
    var box = $(btn.form).select("#group_by_" + axis)[0];
    btn.observe("click", function () {
      if (direction === "Up") {
        moveOptionUp(box);
      } else {
        moveOptionDown(box);
      }
    });
  },

  clear: function () {
    ['group_by_columns', 'group_by_rows'].each(function (type) {
      selectAllOptions(type);
      moveOptions(type, 'group_by_container');
    });
  },
//--------------------- delicious group_by --------------
  sortable_options: function() {
    return {
      tag: 'span',
      only: "drag_element",
      overlap: 'horizontal',
      constraint:'horizontal',
      containment: ['group_by_columns','group_by_rows'],
      dropOnEmpty: true,
      format: /^(.*)$/,
      hoverclass: 'drag_container_accept',
      onUpdate: Reporting.GroupBys.ordering_changed
    };
  },

  ordering_changed: function(container) {
    container.select('.group_by_element').each(function(group_by) {
      Reporting.GroupBys.update_arrow(group_by);
    });
  },

  recreate_sortables: function() {
    Sortable.create('group_by_columns', Reporting.GroupBys.sortable_options());
    Sortable.create('group_by_rows', Reporting.GroupBys.sortable_options());
  },

  initialize_drag_and_drop_areas: function() {
    Reporting.GroupBys.recreate_sortables();
  },

  create_group_by: function(field) {
    var group_by = new Element('span', {
      'class': 'in_row drag_element group_by_element',
      'data-group-by': field
    });
    group_by.identify(); // give it a unique id
    return group_by;
  },

  create_label: function(group_by) {
    var group_by_label = new Element('label', {
      'class': 'in_row group_by_label',
      'for': group_by.identify(),
      'id': group_by.identify() + '_label'
    });
    //init_group_by_hover_effects(group_by_label);
    return group_by_label;
  },

  adding_group_by_enabled: function(field, state) {
    $w('add_group_by_columns add_group_by_rows').each(function(container_id) {
      Reporting.Filters.select_option_enabled($(container_id), field, state);
    });
  },

  arrow_removal_hover: function(arrow, status) {
    if (status) {
      $(arrow).addClassName('arrow_removal_hover');
    }
    else {
      $(arrow).removeClassName('arrow_removal_hover');
    }
  },

  init_arrow: function(group_by) {
    var arrow = new Element('img', {
      'class': 'arrow in_row arrow_left',
      'id': group_by.identify() + '_arrow'
    });
    //init_arrow_hover_effects(arrow);
    arrow.observe('mouseover', function() { Reporting.GroupBys.arrow_removal_hover(arrow, true)  });
    arrow.observe('mouseout',  function() { Reporting.GroupBys.arrow_removal_hover(arrow, false) });
    arrow.observe('mousedown', function() { Reporting.GroupBys.remove_group_by(arrow) });
    return arrow;
  },

  // returns true if the given group is the first group in its container
  is_first: function(group_by) {
    return (($(group_by).previous() == null) || (!($(group_by).previous().className.include('group_by'))));
  },

  // returns true if the given group is the last group in its container
  is_last: function(group_by) {
    return (($(group_by).next() == null) || (!($(group_by).next().className.include('group_by'))));
  },

  update_arrow: function(group_by) {
    if (Reporting.GroupBys.is_last(group_by)) {
        $(group_by.identify() + "_arrow").className = "arrow in_row arrow_left";
    } else {
        $(group_by.identify() + "_arrow").className = "arrow in_row arrow_both";
    }
  },

  add_group_by: function(select) {
    var field, group_by, label, selected_option;
    field = $(select).getValue();
    group_by = Reporting.GroupBys.create_group_by(field);
    selected_option = select.select("[value='" + select.getValue() + "']").first();
    select.up('.drag_container').appendChild(group_by);
    label = Reporting.GroupBys.create_label(group_by);
    label.update(selected_option.readAttribute('data-label'));
    select.select("[value='']").first().selected = true;
    group_by.appendChild(label);
    group_by.appendChild(Reporting.GroupBys.init_arrow(group_by));
    if (!(Reporting.GroupBys.is_first(group_by))) {
      Reporting.GroupBys.update_arrow(group_by.previous());
    }
    Reporting.GroupBys.adding_group_by_enabled(field, false);
    Reporting.GroupBys.recreate_sortables();
  }
};

Reporting.onload(function () {
  ["Left", "Right", "Up", "Down"].each(function (dir) {
    Reporting.GroupBys.attach_move_button(dir);
  });
  ["Up", "Down"].each(function (dir) {
    ["rows", "columns"].each(function (axis) {
      Reporting.GroupBys.attach_sort_button(dir, axis);
    });
  });
//-------------------------------- delicious group_by --------------
  Reporting.GroupBys.initialize_drag_and_drop_areas();
  $('add_group_by_rows').observe("change", function () {
    Reporting.GroupBys.add_group_by(this);
  });
  $('add_group_by_columns').observe("change", function () {
    Reporting.GroupBys.add_group_by(this);
  });
});
