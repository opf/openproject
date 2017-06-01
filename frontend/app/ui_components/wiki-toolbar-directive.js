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

module.exports = function() {
  var help_link_title = I18n.t('js.inplace.link_formatting_help');
  var HELP_LINK_ONCLICK = 'window.open(&quot;' + window.appBasePath + '/help/wiki_syntax&quot;, &quot;&quot;, ' +
                          '&quot;resizable=yes, location=no, width=600, height=640, ' +
                          'menubar=no, status=no, scrollbars=yes&quot;); return false;',
      HELP_LINK_HTML = jQuery('<button title="' + help_link_title + '"' +
                              ' class="jstb_help" ' +
                              ' type="button" ' +
                              ' aria-label="' + help_link_title + '"' +
                              'onclick="' + HELP_LINK_ONCLICK + '"></button>')[0],
      PREVIEW_ENABLE_TEXT = I18n.t('js.inplace.btn_preview_enable'),
      PREVIEW_DISABLE_TEXT = I18n.t('js.inplace.btn_preview_disable'),
      PREVIEW_BUTTON_CLASS = 'jstb_preview',
      PREVIEW_BUTTON_ATTRIBUTES = {
        'class': PREVIEW_BUTTON_CLASS + ' icon-preview icon-small',
        'type': 'button',
        'title': PREVIEW_ENABLE_TEXT,
        'aria-label': PREVIEW_ENABLE_TEXT,
        'text': ''
      };

  function link(scope, element) {
    scope.isPreview = false;
    var wikiToolbar = new jsToolBar(element.get(0));
    wikiToolbar.setHelpLink(HELP_LINK_HTML);
    wikiToolbar.draw();

    var previewButtonAttributes = PREVIEW_BUTTON_ATTRIBUTES;
    previewButtonAttributes.click = function() {
      scope.previewToggle();
      scope.$apply(function() {

        var title = scope.isPreview ? PREVIEW_DISABLE_TEXT : PREVIEW_ENABLE_TEXT;
        var toggledClasses = 'icon-preview icon-ticket-edit -active';

        element.closest('.textarea-wrapper')
               .find('.' + PREVIEW_BUTTON_CLASS).attr('title', title)
                                                .attr('aria-label', title)
                                                .toggleClass(toggledClasses);
      });
    };

    element
      .closest('.textarea-wrapper')
      .find('.jstb_help')
      .after(jQuery('<button>', previewButtonAttributes));
    // changes are made by jQuery, we trigger input event so that
    // ng-model knows that the value changed
    element.closest('.jstEditor').prevAll('.jstElements').find('button').on('click', function() {
      element.trigger('input');
    });
  }

  return {
    restrict: 'AC',
    transclude: false,
    link: link,
    scope: {
      previewToggle: '&'
    }
  };
};
