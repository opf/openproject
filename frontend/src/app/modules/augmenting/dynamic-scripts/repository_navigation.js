//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

(function($) {
  $(function() {
    var revision = $('#revision-identifier-input'),
        form = revision.closest('form'),
        tag = $('#revision-tag-select'),
        branch = $('#revision-branch-select'),
        selects = tag.add(branch),
        branch_selected = branch.length > 0 && revision.val() == branch.val(),
        tag_selected = tag.length > 0 && revision.val() == tag.val();

    var sendForm = function() {
      selects.prop('disable', true);
      form.submit();
      selects.prop('disable', false);
    };

    /*
    If we're viewing a tag or branch, don't display it in the
    revision box
    */
    if (branch_selected || tag_selected) {
      revision.val('');
    }

    /*
    Copy the branch/tag value into the revision box, then disable
    the dropdowns before submitting the form
    */
    selects.on('change', function() {
      var select = $(this);
      revision.val(select.val());
      sendForm();
    });

    /*
    Disable the branch/tag dropdowns before submitting the revision form
    */
    revision.on('keydown', function(e) {
      if (e.keyCode == 13) {
        sendForm();
      }
    });


    // Dir expanders
    var repoBrowser = $('#browser');
    repoBrowser.on('click', '.dir-expander', function() {
      var el = $(this),
          id = $(this).data('element'),
          content = $(id);

          if (expandDir(content)) {
            content.addClass('loading');
            $.ajax({
              url: el.data('url'),
              success: function(response) {
                content.after(response);
                content.removeClass('loading');
                content.addClass('loaded open');
                content.find('a.dir-expander')[0].title = I18n.t('js.label_collapse');
              }
            });
          }
    });

    /**
     * Collapses a directory listing in the repository module
     */
    function collapseScmEntry(content) {
      repoBrowser.find('.' + content.attr('id')).each(function() {
        var el = $(this);
        if (el.hasClass('open')) {
          collapseScmEntry(el);
        }

        el.hide();
        el.toggleClass('open collapsed');
      });

      content.toggleClass('open collapsed')
      content.find('a.dir-expander')[0].title = I18n.t('js.label_expand');
    }

    /**
     * Expands an SCM entry if its loaded
     */
    function expandScmEntry(content) {
      repoBrowser.find('.' + content.attr('id')).each(function() {
        var el = $(this);
        el.show();
        if (el.hasClass('loaded') && !el.hasClass('collapsed')) {
          expandScmEntry(el);
        }

        el.toggleClass('open collapsed')
      });

      content.toggleClass('open collapsed')
      content.find('a.dir-expander')[0].title = I18n.t('js.label_collapse');
    }

    /**
     * Determines whether a dir-expander should load content
     * or simply expand already loaded content.
     */
    function expandDir(content) {
        if (content.hasClass('open')) {
            collapseScmEntry(content);
            return false;
        } else if (content.hasClass('loaded')) {
            expandScmEntry(content);
            return false;
        }
        if (content.hasClass('loading')) {
            return false;
        }
        return true;
    }
  });
}(jQuery));

