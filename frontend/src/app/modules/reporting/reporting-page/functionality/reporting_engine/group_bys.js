//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, selectAllOptions, moveOptions, moveOptionUp, moveOptionDown */

Reporting.GroupBys = (function($){
  var group_by_container_ids = function() {
    var ids = ['group-by--columns', 'group-by--rows'];

    return _.filter(ids, function (i) {
      return $('#' + i).length > 0 ;
    });
  };

  var recreate_sortables = function() {
    var containers = $('.group-by--selected-elements')
                     .toArray();

    dragula(containers,
            {
              // Setting the mirrorContainer to something smaller than the body
              // reduces the performance hit when using dnd.
              mirrorContainer: document.getElementById('group-by--area')
            });
  };

  var initialize_drag_and_drop_areas = function() {
    recreate_sortables();
  };

  var create_label = function(group_by, text) {
    return $('<label></label>')
           .attr('class', 'in_row group-by--label')
           .attr('for', group_by.attr('id'))
           .attr('id', group_by.attr('id') + '_label')
           .html(text);
  };

  var create_remove_button = function(group_by) {
    var remove_link, remove_icon;

    remove_link = $('<a></a>');
    remove_link.attr('class', 'group-by--remove in_row');
    remove_link.attr('id', group_by.attr('id') + '_remove');
    remove_link.attr('href', '');

    remove_icon = $('<span><span>');
    remove_icon.attr('class', 'icon-context icon-close icon4');

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

      remove_group_by(button.closest('.group-by--selected-element'));
  };

  var create_group_by = function(field, caption) {
    var group_by, label, right_arrow, left_arrow, remove_button;
    group_by = $('<span></span>');
    group_by.attr('class', 'group-by--selected-element');
    group_by.attr('data-group-by', field);
    group_by.uniqueId(); // give it a unique id

    label = create_label(group_by, caption);
    group_by.append(label);

    remove_button = create_remove_button(group_by);
    group_by.append(remove_button);

    return group_by;
  };

  // This is whether it is possible to add a new group if <<field>> through the
  // add-group-by select-box or not.
  var adding_group_by_enabled = function(field, state) {
    _.each(['#group-by--add-columns', '#group-by--add-rows'], function(container_id) {
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
        container = jselect.closest('.group-by--container'),
        selected_option = jselect.find("[value='" + field + "']").first(),
        caption = selected_option.attr('data-label');

    Reporting.GroupBys.add_group_by(field, caption, container);
    jselect.find("[value='']").first().attr('selected', true);
  };

  var add_group_by = function(field, caption, container) {
    var group_by, add_groups_select_box, added_container;
    add_groups_select_box = container.find('select').first();
    group_by = Reporting.GroupBys.create_group_by(field, caption);
    added_container = container.find('.group-by--selected-elements');
    added_container.append(group_by);
    adding_group_by_enabled(field, false);
  };

  var clear = function() {
    _.each(visible_group_bys(), function (group_by) {
      $('#' + group_by + ' .group-by--selected-element').each(function() {
        remove_group_by($(this));
      });
    });
  };

  var visible_group_bys = function() {
    var visible = _.filter(group_by_container_ids(), function (container) {
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
    exists: exists,
    group_by_container_ids: group_by_container_ids,
    initialize_drag_and_drop_areas: initialize_drag_and_drop_areas
  };

})(jQuery);

(function($) {
  Reporting.onload(function () {
    Reporting.GroupBys.initialize_drag_and_drop_areas();
    $('#group-by--add-rows, #group-by--add-columns').on('change', function () {
      if (!(Reporting.GroupBys.exists(this.value))) {
        Reporting.GroupBys.add_group_by_from_select(this);
      }
    });
  });
})(jQuery);
