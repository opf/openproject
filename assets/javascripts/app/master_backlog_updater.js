/*jslint indent: 2*/
/*globals window, document, jQuery, RB*/

RB.BacklogsUpdater = (function ($) {
  return RB.Object.create(RB.BoardUpdater, {
    processAllItems: function (data) {
      var self = this;

      // Process all stories
      $(data).find('#stories .story').each(function (i, item) {
        self.processItem(item, false);
      });
    },

    processItem: function (html) {
      var update, target, oldParent, previous, stories;

      update = RB.Factory.initialize(RB.Story, html);

      if ($('#story_' + update.getID()).length === 0) {
        target = update;                                      // Create a new item
      } else {
        target = $('#story_' + update.getID()).data('this');  // Re-use existing item
        oldParent = $('#story_' + update.getID()).parents(".backlog").first().data('this');
        target.refresh(update);
      }

      // Position the story properly in the backlog
      previous = update.$.find(".higher_item_id").text();
      if (previous.length > 0) {
        target.$.insertAfter($('#story_' + previous));
      } else {
        if (target.$.find(".fixed_version_id").text().length === 0) {
          // Story belongs to the product backlog
          stories = $('#owner_backlogs_container .backlog .stories');
        } else {
          // Story belongs to a sprint backlog
          stories = $('#sprint_' + target.$.find(".fixed_version_id").text()).siblings(".stories").first();
        }
        stories.prepend(target.$);
      }

      if (oldParent !== null && oldParent !== undefined) {
        oldParent.refresh();
      }
      target.$.parents(".backlog").first().data('this').refresh();

      // Retain edit mode and focus if user was editing the
      // story before an update was received from the server
      if (target.$.hasClass('editing')) {
        target.edit();
      }
      if (target.$.data('focus') !== null && target.$.data('focus') !== undefined &&
          target.$.data('focus').length > 0) {

        target.$.find("*[name=" + target.$.data('focus') + "]").focus();
      }

      target.$.effect("highlight", { easing: 'easeInExpo' }, 4000);
    },

    start: function () {
      this.params     = 'only=stories';
      this.initialize();
    }
  });
}(jQuery));
