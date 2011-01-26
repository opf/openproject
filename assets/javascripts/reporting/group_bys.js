Reporting.GroupBys = {
  attach_move_button: function(direction) {
    var btn = $$(".buttons.group_by.move.move" + direction)[0];

    if (direction == "Up" || direction == "Down") {
      var axis = "columns";
    } else if (direction == "Left" || direction == "Right") {
      var axis = "rows";
    }

    var selected_container = btn.form.select("#group_by_" + axis)[0];
    var group_by_container = btn.form.group_by_container;

    if (direction == "Down" || direction == "Right") {
      var source_container = selected_container;
      var target_container = group_by_container;
    } else if (direction == "Up" || direction == "Left") {
      var target_container = selected_container;
      var source_container = group_by_container;
    }

    btn.observe("click", function() {
      moveOptions(source_container, target_container);
    });
  },

  attach_sort_button: function(direction, axis) {
    var btn = $$(".buttons.group_by.sort.sort" + direction + ".sort-" + axis)[0];
    var box = btn.form.select("#group_by_" + axis)[0];
    btn.observe("click", function() {
      if (direction == "Up") {
        moveOptionUp(box);
      } else {
        moveOptionDown(box);
      }
    });
  }
};

Reporting.onload(function() {
  ["Left", "Right", "Up", "Down"].each(function(dir) {
    Reporting.GroupBys.attach_move_button(dir);
  });
  ["Up", "Down"].each(function(dir) {
    ["rows", "columns"].each(function(axis) {
      Reporting.GroupBys.attach_sort_button(dir, axis);
    });
  });
});
