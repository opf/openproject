#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe ProjectsHelper, type: :helper do
  include ApplicationHelper
  include ProjectsHelper

  describe '#projects_with_level' do
    let(:root) do
      stub_descendant_of
    end
    let(:child1) { stub_descendant_of(root) }
    let(:grandchild1) { stub_descendant_of(root, child1) }
    let(:grandchild2) { stub_descendant_of(root, child1) }
    let(:grandgrandchild1) { stub_descendant_of(root, child1, grandchild2) }
    let(:child2) { stub_descendant_of(root) }

    def stub_descendant_of(*ancestors)
      wp = build_stubbed(:project)

      allow(wp)
        .to receive(:is_descendant_of?)
        .and_return(false)

      ancestors.each do |ancestor|
        allow(wp)
          .to receive(:is_descendant_of?)
          .with(ancestor)
          .and_return(true)
      end

      wp
    end

    context 'when ordered by hierarchy' do
      let(:projects) do
        [root,
         child1,
         grandchild1,
         grandchild2,
         grandgrandchild1,
         child2]
      end

      it 'returns the projects in the provided order with the appropriate levels' do
        expect { |b| helper.projects_with_level(projects, &b) }
          .to yield_successive_args [root, 0],
                                    [child1, 1],
                                    [grandchild1, 2],
                                    [grandchild2, 2],
                                    [grandgrandchild1, 3],
                                    [child2, 1]
      end
    end

    context 'when ordered by arbitrarily' do
      let(:projects) do
        [grandchild1,
         child1,
         grandchild2,
         grandgrandchild1,
         child2,
         root]
      end

      it 'returns the projects in the provided order with the appropriate levels' do
        expect { |b| helper.projects_with_level(projects, &b) }
          .to yield_successive_args [grandchild1, 0],
                                    [child1, 0],
                                    [grandchild2, 1],
                                    [grandgrandchild1, 2],
                                    [child2, 0],
                                    [root, 0]
      end
    end
  end

  describe '#short_project_description' do
    let(:project) { build_stubbed(:project, description: (('Abcd ' * 5) + "\n") * 11) }

    it 'returns shortened description' do
      expect(helper.short_project_description(project))
        .to eql(((('Abcd ' * 5) + "\n") * 10)[0..-2] + '...')
    end
  end
end
