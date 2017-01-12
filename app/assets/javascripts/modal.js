//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

var ModalHelper = (function() {

  var ModalHelper = function() {
    this._firstLoad = true;
    var modalHelper = this;
    var modalDiv, modalIframe;

    jQuery(document).ready(function () {
      var body = jQuery(document.body);
      // whatever globals there are, they need to be added to the
      // prototype, so that all ModalHelper instances can share them.
      if (ModalHelper._done !== true) {
        // one time initialization
        modalDiv = jQuery('<div/>').css('hidden', true)
                                   .attr('id', 'modalDiv')
                                   .css('display', 'none');
        body.append(modalDiv);

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

        // use jquery.trap.js to keep the keyboard focus within the modal
        // while it's open
        body.trap();

        body.on("keyup", function (e) {
          if (e.which == 27) {
            modalHelper.close();
          }
        });

        modalDiv.data('changed', false);

        var document_host = document.location.href.split("/")[2];
        body.on("click", "a", function (e) {
          var url = jQuery(e.target).attr("href");

          var data = this.href.split("/");
          var link_host = data[2];

          if (link_host && link_host != document_host) {
            window.open(this.href);
            return false;
          }

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

        jQuery(body).on('keyup', 'textarea', function() {
          modalDiv.data('changed', true);
        });

        jQuery(this).trigger("loaded");

        modalDiv.parent().css('visibility', 'visible');

        modalIframe.attr("height", modalDiv.height());

        // we cannot focus an element within
        // the modal before focusing the modal
        modalIframe.focus();

        // foucs an element within the modal so
        // that the user can start tabbing in it
        body.focus();
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
    this.destroyIframe();
    this.modalIframe = this.writeIframe(this.modalDiv);
  };

  ModalHelper.prototype.destroyIframe = function () {
    if (this.modalIframe) {
      this.modalIframe.remove();
    }
  };

  ModalHelper.prototype.writeIframe = function (div) {
    modalIframe = jQuery('<iframe/>').attr("frameBorder", "0px").attr('id', 'modalIframe').attr('width', '100%').attr('height', '100%').attr('name', 'modalIframe');
    div.append(modalIframe);

    modalIframe.bind("load", jQuery.proxy(this.iframeLoadHandler, this));

    return modalIframe;
  };

  ModalHelper.prototype.close = function() {
    jQuery('input:focus, textarea:focus').trigger('blur'); // unfocus inputs and textareas to get the 'onChange' event triggered

    var modalDiv = this.modalDiv;
    if (!this.loadingModal) {
      if (modalDiv && (modalDiv.data('changed') !== true || confirm(I18n.t('js.timelines.really_close_dialog')))) {
        modalDiv.data('changed', false);
        modalDiv.dialog('close');

        this.destroyIframe();

        jQuery(this).trigger("closed");
      }
    }
  };

  ModalHelper.prototype.loading = function() {
    this.modalDiv.parent().css('visibility', 'hidden');

    this.loadingModal = true;
    this.showLoadingModal();
  };

  /** create a modal dialog from url html data
   * @param url url to load html from.
   * @param callback called when done. called with modal div.
   */
  ModalHelper.prototype.createModal = function(url, callback) {
    if (top != self) {
      window.open(url.replace(/(&)?layout=false/g, ""));
      return;
    }

    var modalHelper = this, modalDiv = this.modalDiv, counter = 0;

    url = this.tweakLink(url);

    if (modalHelper.loadingModal) {
      return;
    }

    var calculatedHeight = jQuery(window).height() * 0.8;
    this.modalIframe = modalHelper.writeIframe(modalDiv);

    modalDiv.css('overflow', 'hidden');
    modalDiv.attr("height", calculatedHeight);
    this.modalIframe.attr("height", calculatedHeight);

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
      modalDiv.parent().prepend('<div id="ui-dialog-closer" class="icon icon-close" />')
        .click(jQuery.proxy(this.close, this));
      jQuery('.ui-dialog-titlebar').hide();
      jQuery('.ui-dialog-buttonpane').hide();

      this._firstLoad = false;
    }

    this.loading();

    this.modalIframe.attr("src", url);
  };

  return ModalHelper;
})();
var modalHelperInstance = new ModalHelper();
