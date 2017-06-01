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

/*jshint expr: true*/

describe('Timeline table helper', function() {
  var TimelineTableHelper, TreeNode;

  beforeEach(angular.mock.module('openproject.timelines.helpers', 'openproject.timelines.models'));
  beforeEach(inject(function(_TimelineTableHelper_, _TreeNode_) {
    TimelineTableHelper = _TimelineTableHelper_;
    TreeNode = _TreeNode_;
  }));

  describe('setRowLevelVisibility', function() {
    var setRowLevelVisibility;

    beforeEach(function() {
      setRowLevelVisibility = TimelineTableHelper.setRowLevelVisibility;
    });

    describe('with 3 levels', function() {
      it('should set levels 0 to 3 to visible', function() {
        var nodes = [];
        for(var i = 0; i < 10; i++){
          var node = Object.create(TreeNode);
          node.level = i;
          nodes.push(node);
        }
        setRowLevelVisibility(nodes, 3);

        expect(nodes.filter(function(node){ return node.visible; }).length).to.equal(4);
      });
    });

  });
});
