#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

describe ProjectsHelper do
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

  describe '#project_more_menu_items' do
    # need to use refind: true because @allowed_permissions is cached in the instance
    shared_let(:project, refind: true) { create(:project) }
    shared_let(:current_user) { create(:user, member_in_project: project) }

    subject(:menu) do
      items = project_more_menu_items(project)
      # each item is a [label, href, **link_to_options]
      items.pluck(0)
    end

    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    # "Archive project" menu entry

    context 'when current user is admin' do
      before do
        current_user.update(admin: true)
      end

      it { is_expected.to include(t(:button_archive)) }
    end

    context 'when current user has archive_project permission' do
      before do
        current_user.roles(project).first.add_permission!(:archive_project)
      end

      it { is_expected.to include(t(:button_archive)) }
    end

    context 'when current user does not have archive_project permission' do
      it { is_expected.not_to include(t(:button_archive)) }
    end

    context 'when project is archived' do
      before do
        project.update(active: false)
      end

      it { is_expected.not_to include(t(:button_archive)) }
    end

    # "Project activity" menu entry

    context 'when project does not have activity module enabled' do
      before do
        project.enabled_module_names -= ['activity']
      end

      it { is_expected.not_to include(t(:label_project_activity)) }
    end

    context 'when project has activity module enabled' do
      it { is_expected.to include(t(:label_project_activity)) }
    end
  end
end
