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

jQuery(function($){
  var toggleContent = function(content,selected) {
    var vendor = $('#scm_vendor').val(),
      targetName = '#' + vendor + '-' + selected,
      oldTargets = content.find('.attributes-group').not(targetName);
    var newTarget  = jQuery(targetName);

    // would work with fieldset#disabled, but that's bugged up unto IE11
    // https://connect.microsoft.com/IE/feedbackdetail/view/962368/
    //
    // Ugly workaround: disable all inputs manually, but
    // spare enabling inputs marked with `aria-disabled`
    oldTargets
      .find('input,select')
      .prop('disabled', true);
    oldTargets.hide();

    newTarget
      .find('input,select')
      .not('[aria-disabled="true"]')
      .prop('disabled', false);
    newTarget.show();
  };

  // Submit form when
  $('.repositories--remote-select').change(function() {
    var select = $(this);
    var url = URI(select.data('url')).search({ scm_vendor: select.val() });

    window.location.href = url.toString();
  });

  $("[data-switch='scm_type']")
    .each(function(_i, el) {

      var fs = $(el),
        name = fs.attr('data-switch'),
        switches = fs.find('[name="' + name + '"]'),
        headers = fs.find('.attributes-group--header-text'),
        content = $(el);

      // Focus on first header
      headers.first().focus();

      // Open content if there is only one possible selection
      var checkedInput = jQuery('input[name=scm_type]:checked');
      if(checkedInput.length > 0) {
        toggleContent(content, checkedInput.val());
      }

      // Necessary for accessibilty purpose
      jQuery('#scm_vendor').on('change', function(){
        window.setTimeout(function(){
          document.getElementsByName('scm_type')[0].focus();
        }, 500);
      });

      // Toggle content
      switches.on('change', function() {
        toggleContent(content, this.value);
      });
    });
});

