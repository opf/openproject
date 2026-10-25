# frozen_string_literal: true

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

require "spec_helper" require_module_spec_helper

RSpec.describe AI::Assistance::Place do
  shared_let(:project) { create(:project, identifier: "demo-place") }
  shared_let(:other_project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages use_ai_assistance] }) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:hidden_work_package) { create(:work_package, project: other_project) }

  describe ".from_params" do
    it "takes a visible work package and its project" do
      place = described_class.from_params({ work_package_id: work_package.id.to_s }, user:)

      expect(place).to have_attributes(work_package:, project:)
    end

    it "is nil for a work package or a project that the user cannot see" do
      expect(described_class.from_params({ work_package_id: hidden_work_package.id }, user:)).to be_nil
      expect(described_class.from_params({ project_id: other_project.identifier }, user:)).to be_nil
    end

    it "takes a project by identifier or id" do
      expect(described_class.from_params({ project_id: "demo-place" }, user:).project).to eq(project)
      expect(described_class.from_params({ project_id: project.id.to_s }, user:).project).to eq(project)
    end

    it "has no work package and no project without parameters" do
      expect(described_class.from_params({}, user:)).to have_attributes(work_package: nil, project: nil)
    end
  end

  describe "#allowed?" do
    let(:outsider) { create(:user, member_with_permissions: { other_project => %i[view_work_packages] }) }

    it "needs the permission in the project of the place" do
      expect(described_class.new(work_package:)).to be_allowed(user)
      expect(described_class.new(project:)).to be_allowed(user)
      expect(described_class.new(project: other_project)).not_to be_allowed(user)
    end

    it "needs the permission in any project without a project" do
      expect(described_class.new).to be_allowed(user)
      expect(described_class.new).not_to be_allowed(outsider)
    end
  end
end
