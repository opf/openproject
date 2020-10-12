#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ProjectsHelper, type: :helper do
  include ApplicationHelper
  include ProjectsHelper

  describe '#projects_with_level' do
    let(:root) do
      stub_descendant_of
    end

    def stub_descendant_of(*ancestors)
      wp = FactoryBot.build_stubbed(:project)

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

    let(:child1) { stub_descendant_of(root) }
    let(:grandchild1) { stub_descendant_of(root, child1) }
    let(:grandchild2) { stub_descendant_of(root, child1) }
    let(:grandgrandchild1) { stub_descendant_of(root, child1, grandchild2) }
    let(:child2) { stub_descendant_of(root) }

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

  describe '#projects_level_list_json' do
    subject { helper.projects_level_list_json(projects).to_json }
    let(:projects) { [] }

    describe 'with no project available' do
      it 'renders an empty projects document' do
        is_expected.to have_json_size(0).at_path('projects')
      end
    end

    describe 'with some projects available' do
      let(:projects) do
        p1 = FactoryBot.build(:project, name: 'P1')

        # a result from Project.project_level_list
        [{ project: p1,
           level: 0 },
         { project: FactoryBot.build(:project, name: 'P2', parent: p1),
           level: 1 },
         { project: FactoryBot.build(:project, name: 'P3'),
           level: 0 }]
      end

      it 'renders a projects document with the size of 3 of type array' do
        is_expected.to have_json_size(3).at_path('projects')
      end

      it 'renders all three projects' do
        is_expected.to be_json_eql('P1'.to_json).at_path('projects/0/name')
        is_expected.to be_json_eql('P2'.to_json).at_path('projects/1/name')
        is_expected.to be_json_eql('P3'.to_json).at_path('projects/2/name')
      end

      it 'renders the project levels' do
        is_expected.to be_json_eql(0.to_json).at_path('projects/0/level')
        is_expected.to be_json_eql(1.to_json).at_path('projects/1/level')
        is_expected.to be_json_eql(0.to_json).at_path('projects/2/level')
      end
    end
  end

  context '#short_project_description' do
    let(:project) { FactoryBot.build_stubbed(:project, description: ('Abcd ' * 5 + "\n") * 11) }

    it 'returns shortened description' do
      expect(helper.short_project_description(project))
        .to eql((('Abcd ' * 5 + "\n") * 10)[0..-2] + '...')
    end
  end
end
