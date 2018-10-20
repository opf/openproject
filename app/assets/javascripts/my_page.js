//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

jQuery(document).ready(function($) {

  // Add block
  $('.my-page--block-form').submit(function (evt) {
    var form = $(this);
    var block = $('#block-options').val();
    evt.preventDefault();

    jQuery
      .ajax(
        {
          url: form.attr('action'),
          type: 'POST',
          dataType: 'html',
          data: {
            block: block
          }
      })
      .fail(function(error, text) {
        jQuery(window).trigger(
          'op:notifications:add',
          {
            type: 'error',
            message: I18n.t('js.error.cannot_save_changes_with_message', { error: _.get(error, 'responseText', 'Internal error') })
          }
        );
      })
      .done(function(response) {
        // Add partial to the top container.
        jQuery("#top").prepend(response);

        // Revert options selection back to the default one.
        jQuery('#block-options option').first().prop('selected', true);

        // Disable the option for this block in the blocks-to-add-to-page dropdown.
        jQuery('#block-options option[value="' + block + '"]').attr("disabled", "true");
      });

    return false;
  });

  // Remove block
  $('.my-page--container')
    .on('click', '.my-page--remove-block', function (evt) {
    evt.preventDefault();

    var link = $(this);
    var block = link.data('name');
    var dasherized = link.data('dasherized');

    jQuery
      .ajax(
        {
          url: link.attr('href'),
          type: 'POST',
          dataType: 'html',
          data: {
            block: block
          }
      })
      .fail(function(error) {
        jQuery(window).trigger(
          'op:notifications:add',
          {
            type: 'error',
            message: I18n.t('js.error.cannot_save_changes_with_message', { error: _.get(error, 'responseText', 'Internal error') })
          }
        );
      })
      .done(function() {
        jQuery("#block-" + dasherized).remove();
        // Enable the option for this block in the blocks-to-add-to-page dropdown.
        jQuery('#block-options option[value="' + block + '"]').removeAttr("disabled");
      });

    return false;
  });

  // Canonical list of containers that will exchange draggable elements.
  var containers = jQuery('.dragula-container').toArray();
  var drake = dragula(containers);

  // On 'el' drop, we fire an Ajax request to persist the order chosen by
  // the user. Actual ordering details are handled on the server.
  drake.on('drop', function(el, target, source, sibling){
    var url = window.gon.my_order_blocks_url;

    // Array of target ordered children after this drop.
    var target_ordered_children = jQuery(target).find('.block-wrapper').map(function(){
      return jQuery(this).data('name');
    }).get();

    // Array of source ordered children after this drop.
    var source_ordered_children = jQuery(source).find('.block-wrapper').map(function(){
      return jQuery(this).data('name');
    }).get();

    // We send the source, target, and the new order of the children in both
    // containers to the server.
    jQuery.ajax({
      url: url,
      type: 'POST',
      data: {
        target: jQuery(target).attr('id'),
        source: jQuery(source).attr('id'),
        target_ordered_children: target_ordered_children,
        source_ordered_children: source_ordered_children
      }
    });
  });
});
