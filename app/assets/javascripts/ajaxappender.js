//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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

(function ($) {
  var AjaxAppender = function (options) {
    var append_href,
        close,
        target_container,
        is_inplace,
        is_loaded,
        state_loading,
        state_loaded,
        replace_with_close,
        replace_with_open,
        slideIn,
        init;

    options = $.extend(true,
                       {},
                       { loading_class: 'loading',
                         loading: null,
                         loaded: null,
                         load_target: null,
                         trigger: '.ajax_append',
                         container_class: 'ajax_appended_information',
                         indicator_class: 'ajax_indicator',
                         hide_text: 'Hide',
                         loading_text: null
                       },
                       options);

    close = function () {
      var close_link = $(this),
          information_window = close_link.siblings('.' + options.container_class);

      replace_with_open(close_link);

      information_window.slideUp();
    };

    append_href = function (link) {
      var target = target_container(link),
          loading_div,
          url = link.attr('href');

      if (is_loaded(link)) {
        state_loaded(target, link);
      }
      else {
        state_loading(target);

        $.ajax({ url: url,
                 headers: { Accept: 'text/javascript' },
                 complete: function (jqXHR) {
                             target.html(jqXHR.responseText);

                             state_loaded(target, link);
                           }
               });
      }
    };

    is_inplace = function() {
      return options.load_target === null;
    };

    is_loaded = function(link) {
      var container = target_container(link);

      return container.children().not('.' + options.indicator_class).size() > 0;
    };

    target_container = function(link) {
      var target,
          container_string = '<div class="' + options.container_class + '"></div>',
          container;

      if (is_inplace()) {
        target = link.parent();
      }
      else {
        target = $(options.load_target);
      }

      container = target.find('.' + options.container_class);

      if (container.size() === 0) {
        container = $(container_string);

        target.append(container);
      }

      return container;
    };

    state_loading = function (target) {
      var loading = $('<span class="' + options.indicator_class + '"></span>');

      if (options.loading_text !== null) {
        loading.html(options.loading_text);
      }

      target.addClass(options.loading_class);
      target.append(loading);

      if (options.loading !== null) {
        options.loading.call(this, target);
      }
    };

    state_loaded = function (target, link) {
      target.removeClass(options.loading_class);

      if (is_inplace()) {
        replace_with_close(link, true);
      }

      if (options.loaded !== null) {
        target.slideDown(function() {
          options.loaded.call(this, target, link);
        });
      }
      else{
        target.slideDown();
      }
    };

    replace_with_close = function (to_replace, hide) {
      var close_link = $('<a href="javascript:void(0)">' + options.hide_text + '</a>');

      to_replace.after(close_link);

      if (hide) {
        to_replace.hide();
      }
      else {
        to_replace.remove();
      }

      close_link.click(close);
    };

    replace_with_open = function(to_replace) {
      var load_link = to_replace.siblings(options.trigger);

      to_replace.remove();

      /* this link is never removed, only hidden */
      load_link.show();
    };

    $(options.trigger).click(function(link) {
      append_href($(this));

      return false;
    });

    return this;
  };

  if ($.ajaxAppend) {
    return;
  }

  $.ajaxAppend = function (options) {
    AjaxAppender(options);
    return this;
  };
}(jQuery));
