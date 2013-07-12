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
    var modalHelper = this;
    var modalDiv;

    function formReplacer(form) {
      var submitting = false;
      console.log(pform);
      form = jQuery(form);

      form.submit(function (e) {
        console.log("Form submit!");
        if (!submitting) {
          submitting = true;
          modalHelper.showLoadingModal();
          modalHelper.submitBackground(form, {autoReplace: true});
        }

        return false;
      });
    }

    function modalFunction(e) {
      if (!event.ctrlKey && !event.metaKey) {
        if (jQuery(e.target).attr("href")) {
          url = jQuery(e.target).attr("href");
        }

        if (url) {
          e.preventDefault();

          modalHelper.createModal(modalHelper.setLayoutParameter(url), function (modalDiv) {
            modalDiv.find("form").each(function () {
              formReplacer(this);
            });
          });
        }
      }
    }

    jQuery(document).ready(function () {
      var body = jQuery(document.body);
      // whatever globals there are, they need to be added to the
      // prototype, so that all ModalHelper instances can share them.
      if (ModalHelper.prototype.done !== true) {
        // one time initialization
        modalDiv = jQuery('<div/>').css('hidden', true).attr('id', 'modalDiv');
        body.append(modalDiv);

        /** replace all data-modal links and all inside modal links */
        body.on("click", "[data-modal]", modalFunction);
        modalDiv.on("click", "a", modalFunction);

        // close when body is clicked
        body.click(function(e) {
          if (modalDiv.data('changed') !== undefined && (modalDiv.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog')))) {
            modalDiv.data('changed', false);
            modalDiv.dialog('close');
          } else {
            e.stopPropagation();
          }
        });

        // do not close when element is clicked
        modalDiv.click(function(e) {
          jQuery(e.target).trigger('click.rails');

          if (e.target.className.indexOf("watcher_link") > -1) {
            e.preventDefault();
          }

          e.stopPropagation();
        });
        ModalHelper.prototype.done = true;
      } else {
        modalDiv = jQuery('#modalDiv');
      }

      modalHelper.modalDiv = modalDiv;      
    });

    this.loadingModal = false;
  };

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

  ModalHelper.prototype.setLayoutParameter = function (url) {
    if (url) {
      return url + (url.indexOf('?') != -1 ? "&layout=false" : "?layout=false");
    }
  };

  /** submit a form in the background.
   * @param form: form element
   * @param url: url to submit to. can be undefined if so, url is taken from form.
   * @param callback: called with results
   */
  ModalHelper.prototype.submitBackground = function(form, options, callback) {
    var modalHelper = this;
    var data = form.serialize(), url;

    if (options.url) {
      url = options.url;
    }

    if (typeof url === 'undefined') {
      url = modalHelper.setLayoutParameter(form.attr('action'));
    }

    jQuery.ajax({
      type: 'POST',
      url: url,
      data: data,
      error: function(obj, error) {
        if (typeof callback === "function") {
          callback(obj.status, obj.responseText);
        }
      },
      success: function(response) {
        if (typeof callback === "function") {
          callback(null, response);
        }

        if (options.autoReplace === true) {
          modalHelper.setModalHTML(response);
        }
      }
    });
  };

  ModalHelper.prototype.setModalHTML = function(data) {
    var modalHelper = this;
    var ta = modalHelper.modalDiv, fields;

    ta.data('changed', false);

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

    // hide dialog header
    //TODO: we need a default close button somewhere
    ta.parent().prepend('<div id="ui-dialog-closer" />');
    jQuery('.ui-dialog-titlebar').hide();

    fields = ta.find(":input");
    fields.change(function(e) {
      ta.data('changed', true);
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
            modalHelper.setModalHTML(data);
            modalHelper.hideLoadingModal();

            if (typeof callback === 'function') {
              callback(modalHelper.modalDiv);
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
