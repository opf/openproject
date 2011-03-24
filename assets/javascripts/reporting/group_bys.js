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
      hoverclass: 'drag_container_accept'
    };
  },

  recreate_sortables: function() {
    Sortable.create('group_by_columns', Reporting.GroupBys.sortable_options());
    Sortable.create('group_by_rows', Reporting.GroupBys.sortable_options());
  },

  initialize_drag_and_drop_areas: function() {
    Reporting.GroupBys.recreate_sortables();
  },

  create_group_by: function(field) {
    group_by = document.createElement('span');
    %w('in_row drag_element group_by_element').each(function(klass) {
      group_by.addClassName(klass);
    });
    group_by.identify(); // give it a unique id
    group_by.writeAttribute('data-group-by', field);
    return group_by;
  },

  create_label: function(group_by) {
    group_by_label = document.createElement('label');
    group_by_label.setAttribute('for', group_by.id);
    group_by_label.setAttribute('class', 'in_row group_by_label');
    group_by_label.setAttribute('id', group_by.id + '_label');
    //init_group_by_hover_effects(group_by_label);
    return group_by_label;
  },

  adding_group_by_enabled: function(field, state) {
    Reporting.Filters.select_option_enabled($('add_group_by_columns'), field, state);
    Reporting.Filters.select_option_enabled($('add_group_by_rows'),    field, state);
  },

  add_group_by: function(select) {
    field = select.value;
    group_by = Reporting.GroupBys.create_group_by(field + "_" + select.id);
    group_by.setAttribute('value', field);
    select.up().appendChild(group_by);
    label = Reporting.GroupBys.create_label(group_by);
    label.innerHTML = select.value // = sanitized_selected(select);
    select.value = "";
    group_by.appendChild(label);
    //group_by.appendChild(init_arrow(group_by));
    //if (!(first_in_row(group_by))) {
    //    update_arrow(group_by.previous());
    //}
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
