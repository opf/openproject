/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

RB.TaskboardUpdater = (function ($) {
  return RB.Object.create(RB.BoardUpdater, {

    processAllItems: function (data) {
      var self = this;

      // Process tasks
      $(data).find('.task').each(function (i, v) {
        self.processItem(v, false);
      });

      // Process impediments
      $(data).find('.impediment').each(function (i, v) {
        self.processItem(v, true);
      });
    },

    processItem: function (html, isImpediment) {
      var update = RB.Factory.initialize(isImpediment ? RB.Impediment : RB.Task, html),
          target,
          oldCellId = '',
          newCell,
          idPrefix = '#issue_';

      if ($(idPrefix + update.getID()).length === 0) {
        // Create a new item
        target = update;
      }
      else {
        // Re-use existing item
        target = $(idPrefix + update.getID()).data('this');
        target.refresh(update);
        oldCellId = target.$.parent('td').first().attr('id');
      }

      // Find the correct cell for the item
      newCell = isImpediment ?
            $('#impcell_' + target.$.find('.meta .status_id').text()) :
            $('#' + target.$.find('.meta .story_id').text() + '_' + target.$.find('.meta .status_id').text());

      // Prepend to the cell if it's not already there
      if (oldCellId !== newCell.attr('id')) {
        newCell.prepend(target.$);
      }

      target.$.effect("highlight", {easing: 'easeInExpo'}, 4000);
    },

    start: function () {
      this.params = 'only=tasks,impediments';
      this.initialize();
    }
  });
}(jQuery));
