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

/*globals jQuery, I18n*/

(function($) {
  // $ is prototype
  // @see app/views/my_projects_overviews/page_layout.html.erb

  function recreateSortables() {
    var lists = $$('.list-position'),
        containedPositions = function() {
          var positions = _.map(lists, function(list) {
            return list.readAttribute('id')
          });
          return _.uniq(positions);
        }(),
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
              new Ajax. Request(url, {
                asynchronous: true,
                evalScripts: true,
                parameters: Sortable.serialize(id)
              });
            },
            containment: containedPositions,
            only: 'mypage-box',
            tag: 'div'
          });
        };

    lists.each(destroy);
    lists.each(create);
  }

  function updateSelect() {
      s = $('block-select')
      for (var i = 0; i < s.options.length; i++) {
          if ($('block_' + s.options[i].value)) {
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

  function removeBlock(block) {
      Effect.DropOut(block);
      $(block).remove();
      updateSelect();
  }

  function resetTextilizable(name) {
      $("textile_" + name).setValue(window["page_layout-textile" + name] + "");
      toggleTextilizableVisibility(name);
      return false;
  }

  function editTextilizable(name) {
      var textile_name = $("textile_" + name);
      if (textile_name != null) {
        window["page_layout-textile" + name] = textile_name.getValue();
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
        loading_text: I18n.t("js.ajax.loading"),
        loading_class: 'box loading'
      });

      // this was previously bound in the template
      $('#block-select').on('change', addBlock);

      //initialize the fun!
      recreateSortables();
      updateSelect();
    });
  }(jQuery))
}($));
