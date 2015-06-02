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

module.exports = function() {
  var HELP_LINK_ONCLICK = 'window.open(&quot;/help/wiki_syntax&quot;, &quot;&quot;, ' +
                          '&quot;resizable=yes, location=no, width=600, height=640, ' +
                          'menubar=no, status=no, scrollbars=yes&quot;); return false;',
      HELP_LINK_HTML = jQuery('<button title="' + I18n.t('js.inplace.link_formatting_help') + '"' +
                              ' class="jstb_help icon icon-help" ' +
                              ' type="button" ' +
                              'onclick="' + HELP_LINK_ONCLICK + '">' +
                              '<span class="hidden-for-sighted">' +
                              I18n.t('js.inplace.link_formatting_help') +
                              '</span></button>')[0],
      PREVIEW_ENABLE_TEXT = I18n.t('js.inplace.btn_preview_enable'),
      PREVIEW_DISABLE_TEXT = I18n.t('js.inplace.btn_preview_disable'),
      PREVIEW_BUTTON_CLASS = 'jstb_preview',
      PREVIEW_BUTTON_ATTRIBUTES = {
        'class': PREVIEW_BUTTON_CLASS + ' icon-issue-watched',
        type: 'button',
        title: PREVIEW_ENABLE_TEXT,
        text: ''
      };

  function link(scope, element) {
    scope.isPreview = false;
    var wikiToolbar = new jsToolBar(element.get(0));
    wikiToolbar.setHelpLink(HELP_LINK_HTML);
    wikiToolbar.draw();

    var previewButtonAttributes = PREVIEW_BUTTON_ATTRIBUTES;
    previewButtonAttributes.click = function() {
      scope.$apply(function() {
        scope.isPreview = !scope.isPreview;
        scope.previewToggle();

        var title = scope.isPreview ? PREVIEW_DISABLE_TEXT : PREVIEW_ENABLE_TEXT;
        var toggledClasses = 'icon-issue-watched icon-ticket-edit -active';

        element.closest('.inplace-edit--write-value')
               .find('.' + PREVIEW_BUTTON_CLASS).attr('title', title)
                                                .toggleClass(toggledClasses);
      });
    };

    element
      .closest('.inplace-edit--write-value')
      .find('.jstb_help')
      .after(jQuery('<button>', previewButtonAttributes));
    // changes are made by jQuery, we trigger input event so that
    // ng-model knows that the value changed
    element.closest('.jstEditor').prevAll('.jstElements').find('button').on('click', function() {
      element.trigger('input');
    });
  }

  return {
    restrict: 'A',
    transclude: false,
    link: link,
    scope: {
      previewToggle: '&'
    }
  };
};
