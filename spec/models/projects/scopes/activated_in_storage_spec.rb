# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Projects::Scopes::ActivatedInStorage do
  shared_let(:project) { create(:project) }
  shared_let(:storage) { create(:nextcloud_storage) }
  shared_let(:project_storage) do
    create(:project_storage, project:, storage:)
  end

  shared_let(:other_project) { create(:project) }
  shared_let(:other_storage) { create(:one_drive_storage) }
  shared_let(:other_project_storage) do
    create(:project_storage, project: other_project, storage: other_storage)
  end

  shared_let(:project_without_storage) { create(:project) }

  describe ".activated_in_storage" do
    it "returns projects which use the given storage id" do
      expect(Project.activated_in_storage([storage.id])).to contain_exactly(project)
    end
  end

  describe ".not_activated_in_storage" do
    it "returns projects which do not use the given storage id" do
      expect(Project.not_activated_in_storage([storage.id])).to contain_exactly(other_project, project_without_storage)
    end
  end
end
