//-- copyright
// OpenProject My Project Page Plugin
//
// Copyright (C) 2011-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
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
// See doc/COPYRIGHT.md for more details.
//++

/* globals jQuery, $$, $, Sortable, Effect, Form, Ajax, I18n, _ */
/* jshint camelcase: false */
/* jshint nonew: false */

(function($) {
  // $ is prototype
  // @see app/views/my_projects_overviews/page_layout.html.erb

  function recreateSortables() {
    var lists = $$('.list-position'),
        containedPositions = (function() {
          var positions = _.map(lists, function(list) {
            return list.readAttribute('id');
          });
          return _.uniq(positions);
        }()),
        destroy = function destroy(list) {
          var id = list.readAttribute('id');
          Sortable.destroy(id);
        },
        create = function create(list) {
          var id  = list.readAttribute('id'),
              url = list.readAttribute('data-ajax-url');
          Sortable.create(id, {
            constraint: false,
            dropOnEmpty: true,
            handle: 'handle',
            onUpdate: function updatePosition() {
              new Ajax.Request(url, {
                asynchronous: true,
                evalScripts: true,
                // this might seem like magic, but it actually
                // replaces Sortable.serialize which breaks our
                // block names when they contain underscores
                parameters: (function serialize(id, $) {
                  var element =  $('#' + id),
                      blocks = element.find('.widget-box').map(function() {
                        return this.id.replace(/^block_/, '');
                      }).get();
                  return blocks.map(function(item) {
                    return id + '[]=' + encodeURIComponent(item);
                  }).join('&');
                }(id, jQuery))
              });
            },
            containment: containedPositions,
            only: 'widget-box',
            tag: 'div'
          });
        };

    lists.each(destroy);
    lists.each(create);
  }

  function updateSelect() {
    var s = $('block-select');
    if (s === null) {
      return;
    }
    for (var i = 0; i < s.options.length; i++) {
      var name = s.options[i].value || '';
      // this becomes necessary as the block names are saved with dashes in the db,
      // but their ids use underscores in the frontend - this changes the name to find
      // the block in the DOM
      name = name.replace(/\-/g, '_');
      if ($('block_' + name)) {
        s.options[i].disabled = true;
      } else {
        s.options[i].disabled = false;
      }
    }
    s.options[0].selected = true;
  }

  function afterAddBlock(response) {
    recreateSortables();
    updateSelect();
    editTextilizable(extractBlockName(response));
    new Effect.ScrollTo('list-hidden');
  }

  function extractBlockName(response) {
    return response.responseText.match(/id="block_(.*?)"/)[1];
  }

  function resetTextilizable(name) {
    $('textile_' + name).setValue(window['page_layout-textile' + name] + '');
    toggleTextilizableVisibility(name);
    return false;
  }

  function editTextilizable(name) {
    var textile_name = $('textile_' + name);
    if (textile_name !== null) {
      window['page_layout-textile' + name] = textile_name.getValue();
      toggleTextilizableVisibility(name);
    }
    return false;
  }

  function toggleTextilizableVisibility(name) {
    $(name + '-form-div').toggle();
    $(name + '-preview-div').toggle();
    $(name + '-text').toggle();
  }
  function addBlock() {
    new Ajax.Updater('list-hidden',
                     $('block-form').action,
                     { insertion: 'top',
                       onComplete: afterAddBlock,
                       parameters: Form.serialize('block-form'),
                       evalScripts:true
                     });

    return false;
  }

  // prototype end

  (function($) {
    // from here on, '$' is jQuery

    $(function() {
      $('#users_per_role .all').click(function () {
        $('#users_per_role').html('');
      });

      $.ajaxAppend({
        trigger: '.all',
        indicator_class: 'ajax-indicator',
        load_target: '#users_per_role',
        loading_text: I18n.t('js.ajax.loading'),
        loading_class: 'box loading'
      });

      // this was previously bound in the template directly
      $('#block-select').on('change', addBlock);

      // we need to rebind some of the links constantly, as the content is generated
      // on the page
      function updateBlockLinks() {
        function getBlockName(element) {
          var blockName = element.data('block-name');
          if (!blockName) {
            throw new Error('no block name found for element');
          }
          return blockName;
        }

        // bind textilizable block links
        $('a.reset-textilizable').on('click', function(e) {
          e.preventDefault();
          resetTextilizable(getBlockName($(this)));
        });

        $('a.edit-textilizable').on('click', function(e) {
          e.preventDefault();
          editTextilizable(getBlockName($(this)));
        });
      }

      // initialize the fun! (prototype)
      recreateSortables();
      updateSelect();

      // moar fun
      updateBlockLinks();

      //these are generated blocks, so we have to watch the links inside them

      // TODO: this is exceptionally _not_ fun
      // this attaches the update method to the window in order for it
      // being callable after removal of a block
      window.myPage = window.myPage || {
        updateSelect: updateSelect,
        updateBlockLinks: updateBlockLinks
      };
    });
  }(jQuery));
}($));
