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

Event.observe(window,'load',function() {
  /*
  If we're viewing a tag or branch, don't display it in the
  revision box
  */
  var branch_selected = $('branch') && $('rev').getValue() == $('branch').getValue();
  var tag_selected = $('tag') && $('rev').getValue() == $('tag').getValue();
  if (branch_selected || tag_selected) {
    $('rev').setValue('');
  }

  /*
  Copy the branch/tag value into the revision box, then disable
  the dropdowns before submitting the form
  */
  $$('#branch,#tag').each(function(e) {
    e.observe('change',function(e) {
      $('rev').setValue(e.element().getValue());
      $$('#branch,#tag').invoke('disable');
      e.element().parentNode.submit();
      $$('#branch,#tag').invoke('enable');
    });
  });

  /*
  Disable the branch/tag dropdowns before submitting the revision form
  */
  $('rev').observe('keydown', function(e) {
    if (e.keyCode == 13) {
      $$('#branch,#tag').invoke('disable');
      e.element().parentNode.submit();
      $$('#branch,#tag').invoke('enable');
    }
  });
});
