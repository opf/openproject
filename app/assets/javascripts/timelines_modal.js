/** create a planning modal
 * @param type either new, edit or show.
 * @param projectId id of the project to create the modal for.
 * @param elementId element id to create the modal for. not needed for new type.
 * @param callback called when done
 */
ModalHelper.prototype.createPlanningModal = function(type, projectId, elementId, callback) {
  var modalHelper = this;
  var timeline = modalHelper.timeline;
  var non_api_url = modalHelper.options.url_prefix +
                    modalHelper.options.project_prefix +
                    "/" +
                    projectId +
                    '/planning_elements/';

  if (typeof elementId === 'function') {
    callback = elementId;
    elementId = undefined;
  }
  // in the following lines we create the url to get the data from
  // also we create the url we submit the data to for the edit action.
  if (type === 'new') {
    non_api_url += 'new';
  }  else {
    throw new Error('invalid action. allowed: new');
  }
  //create the modal by using the html the url gives us.
  modalHelper.createModal(non_api_url);
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