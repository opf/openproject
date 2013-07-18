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
    this._firstLoad = true;
    var modalHelper = this;
    var modalDiv, modalIframe;

    function modalFunction(e) {
      if (!e.ctrlKey && !e.metaKey) {
        if (jQuery(e.target).attr("href")) {
          url = jQuery(e.target).attr("href");
        }

        if (url) {
          e.preventDefault();

          modalHelper.createModal(url, function (modalDiv) {});
        }
      }
    }

    jQuery(document).ready(function () {
      var body = jQuery(document.body);
      // whatever globals there are, they need to be added to the
      // prototype, so that all ModalHelper instances can share them.
      if (ModalHelper._done !== true) {
        // one time initialization
        modalDiv = jQuery('<div/>').css('hidden', true).attr('id', 'modalDiv');
        modalIframe = modalHelper.writeIframe(modalDiv);
        body.append(modalDiv);

        /** replace all data-modal links and all inside modal links */
        body.on("click", "[data-modal]", modalFunction);
        modalDiv.on("click", "a", modalFunction);

        // close when body is clicked
        body.on("click", ".ui-widget-overlay", jQuery.proxy(modalHelper.close, modalHelper));

        ModalHelper._done = true;
      } else {
        modalDiv = jQuery('#modalDiv');
        modalIframe = jQuery('#modalIframe');
      }

      modalHelper.modalDiv = modalDiv;
      modalHelper.modalIframe = modalIframe;
    });

    this.loadingModal = false;
  };

  ModalHelper.prototype.tweakLink = function (url) {
    if (url) {
      if (url.indexOf("?layout=false") == -1 && url.indexOf("&layout=false") == -1) {
        return url + (url.indexOf('?') != -1 ? "&layout=false" : "?layout=false");
      } else {
        return url;
      }
    }
  };

  ModalHelper.prototype.iframeLoadHandler = function () {
    try {
      var modalDiv = this.modalDiv, modalIframe = this.modalIframe, modalHelper = this;
      var content = modalIframe.contents();
      var body = content.find("body");

      if (body.html() !== "") {
        this.hideLoadingModal();
        this.loadingModal = false;

        modalDiv.data('changed', false);

        body.on("click", "a", function (e) {
          var url = jQuery(e.target).attr("href");
          if (url) {
            jQuery(e.target).attr("href", modalHelper.tweakLink(url));
          }
        });

        body.on("submit", "form", function (e) {
          var url = jQuery(e.target).attr("action");

          if (url) {
            jQuery(e.target).attr("action", modalHelper.tweakLink(url));
          }
        });

        //tweak body.
        body.find("#footnotes_debug").hide();
        body.css("min-width", "0px");

        body.find(":input").change(function () {
          modalDiv.data('changed', true);
        });

        jQuery(this).trigger("loaded");

        modalDiv.parent().show();

        modalIframe.attr("height", modalDiv.height());
      } else {
        this.showLoadingModal();
      }
    } catch (e) {
      this.loadingModal = false;
      this.hideLoadingModal();
      this.close();
    }
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

  ModalHelper.prototype.rewriteIframe = function () {
    this.modalIframe.remove();
    this.modalIframe = this.writeIframe(this.modalDiv);
  };

  ModalHelper.prototype.writeIframe = function (div) {
    modalIframe = jQuery('<iframe/>').attr("frameBorder", "0px").attr('id', 'modalIframe').attr('width', '100%').attr('height', '100%').attr('name', 'modalIframe');
    div.append(modalIframe);

    modalIframe.bind("load", jQuery.proxy(this.iframeLoadHandler, this));

    return modalIframe;
  };

  ModalHelper.prototype.close = function() {
    var modalDiv = this.modalDiv;
    if (!this.loadingModal) {
      if (modalDiv && (modalDiv.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog')))) {
        modalDiv.data('changed', false);
        modalDiv.dialog('close');

        this.rewriteIframe();

        jQuery(this).trigger("closed");
      }
    }
  };

  ModalHelper.prototype.loading = function() {
    this.modalDiv.parent().hide();

    this.loadingModal = true;
    this.showLoadingModal();
  };

  /** create a modal dialog from url html data
   * @param url url to load html from.
   * @param callback called when done. called with modal div.
   */
  ModalHelper.prototype.createModal = function(url, callback) {
    var modalHelper = this, modalIframe = this.modalIframe, modalDiv = this.modalDiv, counter = 0;

    url = this.tweakLink(url);

    if (modalHelper.loadingModal) {
      return;
    }

    var calculatedHeight = jQuery(window).height() * 0.8;

    modalDiv.attr("height", calculatedHeight);
    modalIframe.attr("height", calculatedHeight);

    modalDiv.dialog({
      modal: true,
      resizable: false,
      draggable: false,
      width: '900px',
      height: calculatedHeight,
      position: {
        my: 'center',
        at: 'center'
      },
      closeOnEscape: false
    });

    if (this._firstLoad) {
      //add closer
      modalDiv.parent().prepend('<div id="ui-dialog-closer" />').click(jQuery.proxy(this.close, this));
      jQuery('.ui-dialog-titlebar').hide();

      this._firstLoad = false;
    }

    this.loading();

    modalIframe.attr("src", url);
  };

  return ModalHelper;
})();
