//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

//requires 'autocompleter'

jQuery(document).ready(function($) {
  var formatSelection = function(item) {
    return OpenProject.Helpers.markupEscape(item.name || (item.project ? item.project.name : ''));
  };

  [
    $("#reporting_reported_project_status_id"),
    $("#timeline_options_initial_outline_expansion"),
    $("#timeline_options_zoom_factor"),
    $("#timeline_options_compare_to_relative_unit"),
    $("#timeline_options_grouping_one_sort"),
    $("#timeline_options_project_sort"),
    $("#timeline_options_grouping_two_sort"),
    $("#timeline_options_planning_element_time_relative_one_unit"),
    $("#timeline_options_planning_element_time_relative_two_unit")
  ].forEach(function (item) {
    $("input[name='" + $(item).attr("name")+"']").remove();

    $(item).select2({
      'minimumResultsForSearch': 12
    });
  });

  $(".cf_boolean_select").each(function (i, item) {
    $("input[name='" + $(item).attr("name")+"']").remove();

    $(item).select2({
      'minimumResultsForSearch': 12
    });
  });

  $(".cf_list_select").each(function (i, item) {
    $(item).autocomplete({
      'multiple': true
    });
  });


  [
    $("#timeline_options_project_responsibles"),
    $("#timeline_options_project_status"),
    $("#timeline_options_project_types"),
    $("#timeline_options_planning_element_responsibles"),
    $("#timeline_options_planning_element_assignee"),
    $("#timeline_options_grouping_two_selection")
  ].forEach(function (item) {
    $(item).autocomplete({ multiple: true,
                           ajax: {null_element: {id: -1, name: I18n.t("js.filter.noneElement")}}
                        });
  });

  [
    $("#timeline_options_planning_element_types"),
    $("#timeline_options_planning_element_time_types"),
    $("#timeline_options_planning_element_status")
  ].forEach(function (item) {
    $(item).autocomplete({
      multiple: true
    });
  });

  var item = $("#timeline_options_columns_");
  item.autocomplete({
    multiple: true,
    sortable: true
  });

  [
    $("#reporting_reporting_to_project_id"),
    $("#project_association_project_b_id")
  ].forEach(function (item) {
    // Stuff borrowed from Core application.js Project Jump Box
    $(item).autocomplete({
      multiple: false,
      formatSelection: formatSelection,
      formatResult : OpenProject.Helpers.Search.formatter,
      matcher      : OpenProject.Helpers.Search.matcher,
      query        : OpenProject.Helpers.Search.projectQueryWithHierarchy(
                          jQuery.proxy(openProject, 'fetchProjects', item.attr("data-ajaxURL")),
                          20),
      ajax: {}
    });
  });

  [
    $("#timeline_options_grouping_one_selection")
  ].forEach(function (item) {
    // Stuff borrowed from Core application.js Project Jump Box
    $(item).autocomplete({
      multiple: true,
      sortable: true,
      formatSelection: formatSelection,
      formatResult : OpenProject.Helpers.Search.formatter,
      matcher      : OpenProject.Helpers.Search.matcher,
      query        : OpenProject.Helpers.Search.projectQueryWithHierarchy(
                          jQuery.proxy(openProject, 'fetchProjects'),
                          20),
      ajax: {null_element: {id: -1, name: I18n.t("js.filter.noneElement")}}
    });
  });

  [
    $("#timeline_options_parents")
  ].forEach(function (item) {
    // Stuff borrowed from Core application.js Project Jump Box
    $(item).autocomplete({
      multiple: true,
      formatSelection: formatSelection,
      formatResult : OpenProject.Helpers.Search.formatter,
      matcher      : OpenProject.Helpers.Search.matcher,
      query        : OpenProject.Helpers.Search.projectQueryWithHierarchy(
                          jQuery.proxy(openProject, 'fetchProjects'),
                          20),
      ajax: {null_element: {id: -1, name: I18n.t("js.filter.noneElement")}}
    });
  });

  var fields = $("#content").find("input")
                            .not("[type='radio']")
                            .not("[class^='select2-']")
                            .not(".button")
                            .not("[type='hidden']");

  fields.each(function(idx, element) {
    var el = $(element);
    if (el.is(":checked") && el.is("[type='checkbox']")) {
      showFieldSet(el);
    }
    if (el.is("[type='text']") && el.val() !== "") {
      showFieldSet(el);
    }
  });
  function showFieldSet(field) {
    field.closest("fieldset").removeClass("collapsed").children("div").show();
  }
});
