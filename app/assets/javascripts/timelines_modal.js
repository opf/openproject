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
  var api_url = modalHelper.options.url_prefix +
                modalHelper.options.api_prefix +
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
  //TODO: escape projectId and elementId.
  if (type === 'new') {
    non_api_url += 'new.js';
  } else if (type === 'edit') {
    if (typeof elementId === 'string' || typeof elementId === 'number') {
      non_api_url += elementId + '/edit.js';
      api_url += elementId + '.json';
    } else {
      throw new Error('need an element id for editing.');
    }
  } else if (type === 'show') {
    if (typeof elementId === 'string' || typeof elementId === 'number') {
      non_api_url += elementId + '.js';
    } else {
      throw new Error('need an element id for showing.');
    }
  } else {
    throw new Error('invalid action. allowed: new, show, edit');
  }
  //create the modal by using the html the url gives us.
  modalHelper.createModal(non_api_url, function(ele) {
    var projects = timeline.projects;
    var project;
    var projectSelect;
    var fields = ele.find(':input');
    ele.data('changed', false);
    var submitFunction = function(e) {
      modalHelper.showLoadingModal();
      if (type === 'new') {
        api_url = modalHelper.options.url_prefix +
                  modalHelper.options.api_prefix +
                  modalHelper.options.project_prefix +
                  "/" +
                  projectSelect.val() +
                  '/planning_elements.json';
      }
      modalHelper.submitBackground(jQuery(this), api_url, function(err, res) {
        var element;
        modalHelper.hideLoadingModal();
        // display errors correctly.
        if (!err) {
          currentURL = '';
          timeline.reload();
          if (elementId === undefined) {
            try {
              // internet explorer has a text attribute instead of textContent.
              element = res.getElementsByTagName('id')[0];
              elementId = element.textContent || element.text;
            } catch (e) {
              console.log(e);
            }
          }
          if (elementId !== undefined) {
            modalHelper.createPlanningModal('show', projectId, elementId);
          }
        } else if (err !== '500') {
          ele.find('.errorExplanation').remove();
          var error = jQuery('<div>').attr('class', 'errorExplanation').attr('id', 'errorExplanation');
          var json = jQuery.parseJSON(res);
          var i, errorSpan, errorFormEle;
          var errorField;
          for (errorField in json.errors) {
            if (json.errors.hasOwnProperty(errorField)) {
          //for (i = 0; i < json.errors.length; i += 1) {
              error.append(
                jQuery('<ul/>').append(
                  jQuery('<li/>').text(I18n.t('js.timelines.' + errorField) + ' ' + json.errors[errorField]))
                );
              try {
                errorSpan = jQuery('<span/>').attr('class', 'errorSpan');
                errorFormEle = jQuery('#planning_element_' + errorField);
                errorFormEle.before(errorSpan);
                errorSpan.append(errorFormEle);
              } catch (e) {
                // nop
              }
            }
          }
          ele.prepend(error);
          ele.scrollTop(0);
        }
      });
      if (e) {
        e.preventDefault();
      }
    };
    //if we want to create a new element, the project must be selectable.
    if (type === 'new') {
      ele.find('tbody').first().prepend(
        jQuery('<tr><th>' + I18n.t('js.timelines.create_planning_select_project') + '</th><td><select id="projectSelect"/></td></tr>')
      );
      projectSelect = ele.find('#projectSelect');
      for (project in projects) {
        if (projects.hasOwnProperty(project)) {
          if (projects[project].permissions.edit_planning_elements === true) {
            projectSelect.append(jQuery('<option/>').attr('value', projects[project].identifier).text(projects[project].name));
          }
        }
      }
      projectSelect.change(function() {
        var planningElementName = ele.find('#planning_element_name').val();
        var planningElementDescription = ele.find('#planning_element_description').val();
        var planningElementType = ele.find('#planning_element_planning_element_type_id').val();
        var planningElementResponsible = ele.find('#planning_element_responsible_id').val();
        var planningElementStartDate = ele.find('#planning_element_start_date').val();
        var planningElementEndDate = ele.find('#planning_element_end_date').val();
        //just overwrite the current planning modal.
        modalHelper.createPlanningModal('new', projectSelect.val(), function(ele) {
          ele.find('#planning_element_name').val(planningElementName);
          ele.find('#planning_element_description').val(planningElementDescription);
          ele.find('#planning_element_planning_element_type_id').val(planningElementType);
          ele.find('#planning_element_responsible_id').val(planningElementResponsible);
          ele.find('#planning_element_start_date').val(planningElementStartDate);
          ele.find('#planning_element_end_date').val(planningElementEndDate);
        });
      });
      // set to given project id.
      projectSelect.val(projectId);
    }
    //create cancel and save button
    if (type === 'new' || type === 'edit') {
      var cancel = jQuery("<a>").addClass("icon").addClass("icon-cancel").text(I18n.t("js.timelines.cancel")).attr("href", "#").click(function (e) {
        e.preventDefault();
        if (ele.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog'))) {
          if (typeof elementId === "undefined") {
            if (ele.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog'))) {
              ele.data('changed', false);
              ele.dialog('close');
            }
          } else {
            modalHelper.createPlanningModal('show', projectId, elementId);
          }
        }
      });
      var save = jQuery("<a>").addClass("icon").addClass("icon-save").text(I18n.t("js.timelines.save")).attr("href", "#").click(function (e) {
        e.preventDefault();
        submitFunction.call(ele.find('form'));
      });
      ele.find('form').prepend(
          jQuery("<div>").append(
            cancel
          ).append(
            save
          ).addClass("contextual")
      );
      //remove old submit/cancel elements
      ele.find('form').find(':submit').css("display", "none");
      ele.find('form').find('[name=cancelButton]').remove();
      //make textareas bigger
      if (ele.height() > 800) {
        ele.find('textarea').attr("rows", 10);
      } else if (ele.height() > 600) {
        ele.find('textarea').attr("rows", 8);
      }
    }
    //overwrite the action for the edit button.
    if (type === 'show') {
      ele.find('.icon-edit').click(function(e) {
        modalHelper.createPlanningModal('edit', projectId, elementId);
        e.preventDefault();
      });
      ele.find('.icon-cancel').click(function(e) {
        modalHelper.showLoadingModal();
        modalHelper.submitBackground(jQuery(ele.find('.icon-cancel').parent()[0]),
          function(err, res) {
            modalHelper.hideLoadingModal();
            // display errors correctly.
            if (!err) {
              ele.dialog('close');
              timeline.reload();
            }
          }
        );
        e.preventDefault();
      });
      ele.find('.icon-del').click(function(e) {
        var tokenName, token, action, data = {};
        var url = modalHelper.options.url_prefix +
                  modalHelper.options.project_prefix +
                  "/" +
                  projectId +
                  '/planning_elements/';
        tokenName = jQuery('meta[name=csrf-param]').attr('content');
        token = jQuery('meta[name=csrf-token]').attr('content');
        if (jQuery(this).attr('href').indexOf("destroy") == -1) {
          modalHelper.showLoadingModal();
          action = 'delete';
          data['_method'] = 'delete';
          data[tokenName] = token;
          jQuery.post(url + elementId + '/move_to_trash',
            data,
            function() {
              modalHelper.hideLoadingModal();
              ele.dialog('close');
              timeline.reload();
            }).error(function() {
              modalHelper.hideLoadingModal();
              alert(I18n.t('js.timelines.error'));
            });
          //move to bin
        } else if (confirm(I18n.t('js.timelines.really_delete_planning_element'))) {
          modalHelper.showLoadingModal();
          action = 'delete';
          data['_method'] = 'delete';
          data[tokenName] = token;
          data.commit = 'delete';
          jQuery.post(url + elementId,
            data,
            function() {
              modalHelper.hideLoadingModal();
              ele.dialog('close');
              timeline.reload();
            }).error(function() {
              modalHelper.hideLoadingModal();
              alert(I18n.t('js.timelines.error'));
            });
          //move to bin
        }
        e.preventDefault();
      });
    }
    fields.change(function(e) {
      ele.data('changed', true);
    });
    // calendar click must be stopped so it does not close the modal.
    ele.find('.calendar-trigger').click(function() {
      jQuery('.calendar').click(function(e) {
        e.stopPropagation();
      }).css('zIndex', 2000);
    });
    // if a form is submitted, we stop it and submit it in the background.
    ele.find('form').submit(submitFunction);
    if (typeof callback === 'function') {
      callback(ele);
    }
  });
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