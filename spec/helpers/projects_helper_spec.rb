#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

  before do
    User.delete_all
    Version.delete_all
    Project.delete_all

    set_language_if_valid('en')
    User.current = nil
  end

  let(:test_project)  { FactoryBot.create :valid_project }

  describe 'a version' do
    let(:version) { FactoryBot.create :version, project: test_project }

    it 'can be formatted' do
      expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
    end

    it 'can be formatted within a project' do
      @project = test_project
      expect(format_version_name(version)).to eq(version.name)
    end

    it 'does not create a link, without permission' do
      expect(link_to_version(version)).to eq("#{test_project.name} - #{version.name}")
    end

    describe 'with a valid user' do
      let(:user) { FactoryBot.create :user, member_in_project: test_project }
      before do login_as(user) end

      it 'generates a link' do
        expect(link_to_version(version)).to eq("<a href=\"/versions/#{version.id}\">#{test_project.name} - #{version.name}</a>")
      end

      it 'generates a link within a project' do
        @project = test_project
        expect(link_to_version(version)).to eq("<a href=\"/versions/#{version.id}\">#{version.name}</a>")
      end
    end

    describe 'when generating options-tags' do
      it 'generates nothing without a version' do
        expect(version_options_for_select([])).to be_empty
      end

      it 'generates an option tag' do
        expect(version_options_for_select([], version)).to eq("<option selected=\"selected\" value=\"#{version.id}\">#{version.name}</option>")
      end
    end
  end

  describe 'a system version' do
    let(:version) { FactoryBot.create :version, project: test_project, sharing: 'system' }

    it 'can be formatted' do
      expect(format_version_name(version)).to eq("#{test_project.name} - #{version.name}")
    end
  end

  describe 'an invalid version' do
    let(:version) { Object }

    it 'does not generate a link' do
      expect(link_to_version(Object)).to be_empty
    end
  end

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
end
