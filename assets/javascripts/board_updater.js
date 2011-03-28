/*jslint indent: 2*/
/*globals window, document, jQuery, RB, setTimeout*/

/***************************************
  BOARD UPDATER
  Base object that is extended by
  board-type-specific updaters
***************************************/

RB.BoardUpdater = (function ($) {
  return RB.Object.create({

    initialize: function () {
      var self = this;

      $('#refresh').click(function (e, u) {
        self.handleRefreshClick(e, u);
      });
      $('#disable_autorefresh').click(function (e, u) {
        self.handleDisableAutorefreshClick(e, u);
      });

      this.loadPreferences();
      this.pollWait = 1000;
      this.poll();
    },

    adjustPollWait: function (itemsReceived) {
      itemsReceived = itemsReceived || 0;

      if (itemsReceived === 0 && this.pollWait < 300000 && !$('body').hasClass('no_autorefresh')) {
        this.pollWait += 250;
      }
      else {
        this.pollWait = 1000;
      }
    },

    getData: function () {
      var self = this;

      RB.ajax({
        type      : "GET",
        url       : RB.urlFor('show_updated_items', {id: RB.constants.project_id}) + '?' + self.params,
        data      : {since : $('#last_updated').text()},
        beforeSend: function () {
          $('body').addClass('loading');
        },
        success   : this.processData,
        error     : this.processError
      });
    },

    handleDisableAutorefreshClick: function (event, ui) {
      $('body').toggleClass('no_autorefresh');
      RB.UserPreferences.set('autorefresh', !$('body').hasClass('no_autorefresh'));
      if (!$('body').hasClass('no_autorefresh')) {
        this.pollWait = 1000;
        this.poll();
      }
      this.updateAutorefreshText();
    },

    handleRefreshClick: function (event, ui) {
      this.getData();
    },

    loadPreferences: function () {
      var ar = RB.UserPreferences.get('autorefresh') === "true";

      if (ar) {
        $('body').removeClass('no_autorefresh');
      } else {
        $('body').addClass('no_autorefresh');
      }
      this.updateAutorefreshText();
    },

    poll: function () {
      if (!$('body').hasClass('no_autorefresh')) {
        setTimeout(this.getData, this.pollWait);
      }
      else {
        return false;
      }
    },

    processAllItems: function () {
      throw "RB.BoardUpdater.processAllItems() was not overriden by child object";
    },

    processData: function (data, textStatus, xhr) {
      var latestUpdate;

      $('body').removeClass('loading');

      latestUpdate = $(data).find('#last_updated').text();
      if (latestUpdate.length > 0) {
        $('#last_updated').text(latestUpdate);
      }

      this.processAllItems(data);
      this.adjustPollWait($(data).children(":not(.meta)").length);
      this.poll();
    },

    processError: function () {
      this.adjustPollWait(0);
      this.poll();
    },

    updateAutorefreshText: function () {
      if ($('body').hasClass('no_autorefresh')) {
        $('#disable_autorefresh').text('Enable Auto-refresh');
      }
      else {
        $('#disable_autorefresh').text('Disable Auto-refresh');
      }
    }
  });
}(jQuery));
