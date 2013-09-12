(function ($, undefined) {
  "use strict";

  function TopMenu (menu_container) {
    this.menu_container = $(menu_container);
    this.setup(menu_container);
  }

  TopMenu.prototype = $.extend(TopMenu.prototype, {
    setup: function () {
      var self = this;
      this.oldBrowser = parseInt($.browser.version, 10) < 8 && $.browser.msie;
      this.hover = false;
      this.menuIsOpen = false;
      this.withHeadingFoldOutAtBorder();
      this.setupDropdownHoverAndClick();
      this.registerEventHandlers();
      this.closeOnBodyClick();
    },

    toggleClick: function (dropdown) {
      if (this.menuIsOpen) {
        if (this.isOpen(dropdown)) {
          this.closing();
        } else {
          this.open(dropdown);
        }
      } else {
        this.opening();
        this.open(dropdown);
      }
    },

    // somebody opens the menu via click, hover possible afterwards
    opening: function () {
      this.startHover();
      this.menuIsOpen = true;
      this.menu_container.trigger("openedMenu", this.menu_container);
    },

    // the entire menu gets closed, no hover possible afterwards
    closing: function () {
      this.stopHover();
      this.closeAllItems();
      this.menuIsOpen = false;
      this.menu_container.trigger("closedMenu", this.menu_container);
    },

    stopHover: function () {
      this.hover = false;
      this.menu_container.removeClass("hover");
    },

    startHover: function () {
      this.hover = true;
      this.menu_container.addClass("hover");
    },

    closeAllItems: function () {
      var self = this;
      this.openDropdowns().each(function (ix, item) {
        self.close($(item));
      });
    },

    closeOnBodyClick: function () {
      var self = this;
      $('html').click(function() {
        if (self.menuIsOpen) {
          self.closing();
        }
      });
    },

    openDropdowns: function () {
      return this.dropdowns().filter(".open");
    },

    dropdowns: function () {
      return this.menu_container.find(" > li.drop-down");
    },

    withHeadingFoldOutAtBorder: function () {
      var menu_start_position;
      if (this.menu_container.next().get(0) != undefined && (this.menu_container.next().get(0).tagName == 'H2')){
        menu_start_position = this.menu_container.next().innerHeight() + this.menu_container.next().position().top;
        this.menu_container.find("ul.action_menu_more").css({ top: menu_start_position });
      }
      else if(this.menu_container.next().hasClass("wiki-content") && this.menu_container.next().children().next().first().get(0) != undefined && this.menu_container.next().children().next().first().get(0).tagName == 'H1'){
        var wiki_heading = this.menu_container.next().children().next().first();
        menu_start_position = wiki_heading.innerHeight() + wiki_heading.position().top;
        this.menu_container.find("ul.action_menu_more").css({ top: menu_start_position });
      }
    },

    setupDropdownHoverAndClick: function () {
      var self = this;
      this.dropdowns().each(function (ix, it) {
        $(it).click(function () {
          self.toggleClick($(this));
          return false;
        });
        $(it).hover(function () {
          // only do something if the menu is in hover mode
          // AND the dropdown we hover on is not currently open anyways
          if (self.hover && self.isClosed($(this))) {
            self.open($(this));
          }  
        });
      });
    },

    isOpen: function (dropdown) {
      return dropdown.filter(".open").length == 1;
    },

    isClosed: function (dropdown) {
      return !this.isOpen(dropdown);
    },

    open: function (dropdown) {
      this.dontCloseWhenUsing(dropdown);
      this.closeOtherItems(dropdown);
      this.slideAndFocus(dropdown);
      dropdown.trigger("opened", dropdown);
    },

    close: function (dropdown) {
      this.slideUp(dropdown);
      dropdown.trigger("closed", dropdown);
    },

    closeOtherItems: function (dropdown) {
      var self = this;
      this.openDropdowns().filter(function (ix, it) {
        return $(it) != $(dropdown);
      }).each(function (ix, it) {
        self.close($(it));
      })
    },

    dontCloseWhenUsing: function (dropdown) {
      $(dropdown).find("li").click(function (event) {
        event.stopPropagation();
      });
      $(dropdown).bind("mousedown mouseup click", function (event) {
        event.stopPropagation();
      });
    },

    slideAndFocus: function (dropdown) {
      this.slideDown(dropdown);
      this.focusFirstInputOrLink(dropdown);
    },

    slideDown: function (dropdown) {
      var toDrop = dropdown.find("> ul");
      dropdown.addClass("open");
      if (this.oldBrowser) {
        toDrop.show();

        // this forces IE to redraw the menu area, un-bollocksing things
        $("#main-menu").css({paddingBottom:5}).animate({paddingBottom:0}, 10);

      } else {
        toDrop.slideDown(animationRate);
      }
    },

    slideUp: function (dropdown) {
      var toDrop = $(dropdown).find("> ul");
      dropdown.removeClass("open");
      if (this.oldBrowser) {
        toDrop.hide();

        // this forces IE to redraw the menu area, un-bollocksing things
        $("#main-menu").css({paddingBottom:5}).animate({paddingBottom:0}, 10);

      } else {
        toDrop.slideUp(animationRate);
      }
    },

    // If there is ANY input, it will have precedence over links,
    // i.e. links will only get focussed, if there is NO input whatsoever
    focusFirstInputOrLink: function (dropdown) {
      var toFocus = dropdown.find("ul :input:visible:first");
      if (toFocus.length == 0) {
        toFocus = dropdown.find("ul a:visible:first");
      }
      toFocus.blur();
      setTimeout(function() {
        toFocus.focus();
      }, 100);
    },

    registerEventHandlers: function () {
      var self = this;
      this.menu_container.on("closeDropDown", function (event) {
        self.close($(event.target));
      }).on("openDropDown", function (event) {
        self.open($(event.target));
      }).on("closeMenu", function () {
        self.closing();
      }).on("openMenu", function () {
        self.open(self.dropdowns().first());
        self.opening();
      });
    }
  });

  $.fn.top_menu = function () {
    $(this).each(function () {
      new TopMenu($(this));
    });
  }
}(jQuery));

jQuery(document).ready(function($) {
  $("#account-nav").top_menu();
});
