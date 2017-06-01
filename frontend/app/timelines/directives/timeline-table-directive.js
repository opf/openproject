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

module.exports = function(TimelineTableHelper) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/timelines/timeline_table.html',
    scope: true,
    link: function(scope, element, attributes) {
      scope.columns = scope.timeline.options.columns;
      scope.height = scope.timeline.decoHeight();
      scope.excludeEmpty = scope.timeline.options.exclude_empty === 'yes';
      scope.isGrouping = scope.timeline.isGrouping();
      scope.hideTreeRoot = scope.isGrouping || scope.timeline.options.hide_tree_root;

      scope.toggleRowExpansion = function(row){
        if(row.expanded) {
          var expansionMethod = function(node){ node.resetVisible(); };
        } else {
          var expansionMethod = function(node){ node.setVisible(); };
        }

        TimelineTableHelper.applyToNodes(row.childNodes, expansionMethod, row.expanded);
        row.expanded = !row.expanded;
        TimelineTableHelper.setLastVisible(scope.rows);
      };
    }
  };
};
