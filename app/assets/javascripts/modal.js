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

var ModalHelper = (function() {

  var ModalHelper = function() {
    var modalDiv;
    var body = jQuery('body');
    // whatever globals there are, they need to be added to the
    // prototype, so that all ModalHelper instances can share them.
    if (ModalHelper.prototype.done !== true) {
      // one time initialization
      modalDiv = jQuery('<div/>').css('hidden', true).attr('id', 'modalDiv');
      body.append(modalDiv);
      // close when body is clicked
      body.click(function(e) {
        if (modalDiv.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog'))) {
          modalDiv.data('changed', false);
          modalDiv.dialog('close');
        } else {
          e.stopPropagation();
        }
      });
      // do not close when element is clicked
      modalDiv.click(function(e) {
        e.stopPropagation();
      });
      ModalHelper.prototype.done = true;
    } else {
      modalDiv = jQuery('#modalDiv');
    }

    this.modalDiv = modalDiv;
    this.loadingModal = false;
  }

  /** display the loading modal (spinner in a box)
   * also fix z-index so it is always on top.
   */
  ModalHelper.prototype.showLoadingModal = function() {
    jQuery('#ajax-indicator').show().css('zIndex', 1020);
  };

  /** hide the loading modal */
  ModalHelper.prototype.hideLoadingModal = function() {
    jQuery('#ajax-indicator').hide();
  };

  /** submit a form in the background.
   * @param form: form element
   * @param url: url to submit to. can be undefined if so, url is taken from form.
   * @param callback: called with results
   */
  //TODO fix this inconsistency w/ optional url.
  ModalHelper.prototype.submitBackground = function(form, url, callback) {
    var data = form.serialize();

    if (typeof url === 'function') {
      callback = url;
      url = undefined;
    }

    if (typeof url === 'undefined') {
      url = form.attr('action');
    }

    jQuery.ajax({
      type: 'POST',
      url: url,
      data: data,
      error: function(obj, error) {
        callback(obj.status, obj.responseText);
      },
      success: function(response) {
        callback(null, response);
      }
    });
  };

  /** create a modal dialog from url html data
   * @param url url to load html from.
   * @param callback called when done. called with modal div.
   */
  ModalHelper.prototype.createModal = function(url, callback) {
    var modalHelper = this;

    if (modalHelper.loadingModal) {
      return;
    }

    modalHelper.loadingModal = true;

    try {

      modalHelper.showLoadingModal();

      // get html for url.
      jQuery.ajax({
        type: 'GET',
        url: url,
        dataType: 'html',
        error: function(obj, error) {
          modalHelper.hideLoadingModal();
          modalHelper.loadingModal = false;
        },
        success: function(data) {
          try {
            debugger;
            modalHelper.hideLoadingModal();
            currentURL = url;
            var ta = modalHelper.modalDiv;

            // write html to div
            ta.html(data);

            // show dialog.
            ta.dialog({
              modal: true,
              resizable: false,
              draggable: false,
              width: '900px',
              height: jQuery(window).height() * 0.8,
              position: {
                my: 'center',
                at: 'center'
              }
            });

            // close when cancel is clicked.
            ta.find('[name=cancelButton]').click(function(e) {
              e.preventDefault();
              if (ta.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog'))) {
                ta.data('changed', false);
                ta.dialog('close');
              }
            });

            // hide dialog header
            //TODO: we need a default close button somewhere
            ta.parent().prepend('<div id="ui-dialog-closer" />');
            jQuery('.ui-dialog-titlebar').hide();

            if (typeof callback === 'function') {
              callback(ta);
            }

          } catch (e) {
            console.log(e);
          } finally {
            modalHelper.loadingModal = false;
          }
        }
      });

    } catch (e) {
      console.log(e);
      modalHelper.loadingModal = false;
    }
  };

  return ModalHelper;
})();