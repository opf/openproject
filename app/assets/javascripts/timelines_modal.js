//-- copyright
// OpenProject is a project management system.
//
// Copyright (C) 2012-2013 the OpenProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

/** create a work package creation modal
 * @param projectId id of the project to create the modal for.
 */
ModalHelper.prototype.create = function(projectId) {
  var modalHelper = this;
  var url = modalHelper.options.url_prefix +
                    modalHelper.options.project_prefix +
                    "/" +
                    projectId +
                    '/work_packages/new';

  //create the modal by using the html the url gives us.
  modalHelper.createModal(url);
};
ModalHelper.prototype.setupTimeline = function(timeline, options) {
  this.timeline = timeline;
  this.options = options;

  // every-time initialization
  jQuery(timeline).on('dataLoaded', function() {
    var projects = timeline.projects;
    var project;
    for (project in projects) {
      if (projects.hasOwnProperty(project)) {
        if (projects[project].permissions.edit_planning_elements === true) {
          jQuery('#newPlanning').show();
          break;
        }
      }
    }
  });
};