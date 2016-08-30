//-- copyright
// ReportingEngine
//
// Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//++

/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, selectAllOptions, moveOptions, moveOptionUp, moveOptionDown */

Reporting.GroupBys = (function($){
  var group_by_container_ids = function() {
    var ids = ['group_by_columns', 'group_by_rows'];

    return _.select(ids, function (i) {
      return $('#' + i).length > 0 ;
    });
  };

  var sortable_options = function() {
    return {
      tag: 'span',
      only: "drag_element",
      overlap: 'horizontal',
      constraint:'horizontal',
      containment: group_by_container_ids(),
      dropOnEmpty: true,
      hoverclass: 'drag_container_accept'
    };
  };

  var recreate_sortables = function() {
    _.each(group_by_container_ids(), function(id) {
      Sortable.create(id, sortable_options());
    });
  };

  var initialize_drag_and_drop_areas = function() {
    recreate_sortables();
  };

  var create_label = function(group_by, text) {
    return $('<label></label>')
           .attr('class', 'in_row group_by_label')
           .attr('for', group_by.attr('id'))
           .attr('id', group_by.attr('id') + '_label')
           .html(text);
  };

  var create_remove_button = function(group_by) {
    var remove_link, remove_icon;

    remove_link = $('<a></a>');
    remove_link.attr('class', 'group_by_remove in_row');
    remove_link.attr('id', group_by.attr('id') + '_remove');
    remove_link.attr('href', '');

    remove_icon = $('#hidden_remove_img').clone();
    remove_icon.removeAttr('id');
    remove_icon.removeAttr('style');
    remove_icon.removeAttr('class');

    remove_link.attr('title', I18n.t("js.reporting_engine.label_remove") + ' ' + group_by.find('label').html());
    remove_icon.attr('alt', I18n.t("js.reporting_engine.label_remove") + ' ' + group_by.find('label').html());

    remove_link.on('click', function(e) {
      e.preventDefault();
      remove_element_event_action(e, group_by, remove_link);
    });
    remove_link.on('keypress', function(e) {
      /* keyCode 32: Space */
      if (e.keyCode == 32) {
        e.preventDefault();
        remove_element_event_action(e, group_by, remove_link);
      }
    });
    remove_link.append(remove_icon);
    return remove_link;
  };

  var remove_element_event_action = function(event, group_by, button) {
      var link_node = group_by.next('span').find('a'),
          select_node = group_by.next('select');

      if (link_node.length) {
        link_node.focus();
      }
      else if (select_node.length) {
        select_node.focus();
      }

      remove_group_by(button.closest('.group_by_element'));
  };

  var create_arrow = function(group_by, position) {
    var arrow = $('<span></span>');
    arrow.attr('class', 'arrow in_row arrow_' + position);
    arrow.attr('id', group_by.attr('id') + '_arrow_' + position);

    return arrow;
  };

  var create_group_by = function(field, caption) {
    var group_by, label, right_arrow, left_arrow, remove_button;
    group_by = $('<span></span>');
    group_by.attr('class', 'in_row drag_element group_by_element');
    group_by.attr('data-group-by', field);
    group_by.uniqueId(); // give it a unique id

    left_arrow = create_arrow(group_by, 'left');
    group_by.append(left_arrow);

    label = create_label(group_by, caption);
    init_group_by_hover_effects($().add(group_by).add(label));
    group_by.append(label);

    remove_button = create_remove_button(group_by);
    group_by.append(remove_button);

    right_arrow = create_arrow(group_by, 'right');
    group_by.append(right_arrow);
    return group_by;
  };

  // on mouse_over of a group_by or it's label, change the color of the group_by
  // also change the color of the arrows
  var init_group_by_hover_effects = function(elements) {
    elements.on('mouseover mouseout', function(event) {
      group_by_hover_effect(event, event.type === 'mouseover');
    });
  };

  var group_by_hover_effect = function(event, do_hover) {
    var group_by = $(Event.element(event));
    // we possibly hit a tag inside the group_by, so go search the group_by then
    if (!group_by.hasClass('group_by_element')) {
      group_by = group_by.closest('.group_by_element');
    }
    if (group_by !== null) {
      group_by_hover(group_by, do_hover);
    }
  };

  var group_by_hover = function(group_by, state) {
    if (state) {
      group_by.children().addClass('hover');
    } else {
      group_by.children().removeClass('hover');
    }
  };

  // This is whether it is possible to add a new group if <<field>> through the
  // add-group-by select-box or not.
  var adding_group_by_enabled = function(field, state) {
    _.each(['#add_group_by_columns', '#add_group_by_rows'], function(container_id) {
      Reporting.Filters.select_option_enabled($(container_id), field, state);
    });
  };

  var remove_group_by = function(group_by) {
    adding_group_by_enabled(group_by.attr('data-group-by'), true);
    group_by.remove();
  };

  var add_group_by_from_select = function(select) {
    var jselect = $(select),
        field = jselect.val(),
        container = jselect.closest('.drag_container'),
        selected_option = jselect.find("[value='" + field + "']").first(),
        caption = selected_option.attr('data-label');

    Reporting.GroupBys.add_group_by(field, caption, container);
    jselect.find("[value='']").first().attr('selected', true);
  };

  var add_group_by = function(field, caption, container) {
    var group_by, add_groups_select_box;
    add_groups_select_box = container.find('select').first();
    group_by = Reporting.GroupBys.create_group_by(field, caption);
    add_groups_select_box.before(group_by);
    adding_group_by_enabled(field, false);
    recreate_sortables();
  };

  var clear = function() {
    _.each(visible_group_bys(), function (group_by) {
      $('#' + group_by).find('.group_by_element').each(function() {
        remove_group_by($(this));
      });
    });
  };

  var visible_group_bys = function() {
    var visible = _.select(Reporting.GroupBys.group_by_container_ids(), function (container) {
      return $('#' + container).find('[data-group-by]');
    });

    return _.flatten(visible);
  };

  var exists = function(group_by_name) {
    return _.some(visible_group_bys(), function (grp) {
      return $('#' + grp).attr('data-group-by') === group_by_name;
    });
  };

  return {
    add_group_by: add_group_by,
    add_group_by_from_select: add_group_by_from_select,
    clear: clear,
    create_group_by: create_group_by,
    create_arrow: create_arrow,
    exists: exists,
    group_by_container_ids: group_by_container_ids,
    initialize_drag_and_drop_areas: initialize_drag_and_drop_areas
  };

})(jQuery);

(function($) {
  Reporting.onload(function () {
    Reporting.GroupBys.initialize_drag_and_drop_areas();
    $('#add_group_by_rows, #add_group_by_columns').on('change', function () {
      if (!(Reporting.GroupBys.exists(this.value))) {
        Reporting.GroupBys.add_group_by_from_select(this);
      }
    });
  });
})(jQuery);
