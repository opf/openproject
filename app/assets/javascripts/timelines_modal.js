/** create a planning modal
 * @param type either new, edit or show.
 * @param projectId id of the project to create the modal for.
 * @param elementId element id to create the modal for. not needed for new type.
 * @param callback called when done
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