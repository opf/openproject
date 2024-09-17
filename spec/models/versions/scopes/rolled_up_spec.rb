#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Versions::Scopes::RolledUp do
  shared_let(:parent_project) { create(:project) }
  shared_let(:project) { create(:project, parent: parent_project) }
  shared_let(:sibling_project) { create(:project, parent: parent_project) }
  shared_let(:child_project) { create(:project, parent: project) }
  shared_let(:grand_child_project) { create(:project, parent: child_project) }
  shared_let(:version) { create(:version, project:) }
  shared_let(:child_version) { create(:version, project: child_project) }
  shared_let(:grand_child_version) { create(:version, project: grand_child_project) }
  shared_let(:parent_version) { create(:version, project: parent_project) }
  shared_let(:sibling_version) { create(:version, project: sibling_project) }

  describe ".rolled_up" do
    it "includes versions of self and all descendants" do
      expect(project.rolled_up_versions)
        .to contain_exactly(version, child_version, grand_child_version)
    end

    it "excludes versions from inactive projects" do
      grand_child_project.update(active: false)

      expect(project.rolled_up_versions)
        .to contain_exactly(version, child_version)
    end
  end
end
