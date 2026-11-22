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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::Exports::StatusReportJson do
  let(:type) { create(:type, name: "Status Report") }
  let(:project) { create(:project, types: [type]) }
  let(:report) { create(:work_package, project:, type:, subject: "November status report") }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages export_work_packages] }) }

  before { login_as(user) }

  describe "embedded tables" do
    let(:query) { create(:global_query, column_names: %i[id subject status]) }
    let!(:included) { create(:work_package, project:, type:, subject: "Included milestone") }
    let!(:unrelated) { create(:work_package, project:, type:, subject: "Unrelated milestone") }
    let!(:inaccessible) { create(:work_package, project: create(:project, public: false), type:) }

    before do
      variant = type.default_variant
      variant.attribute_groups = variant.default_attribute_groups + [["Milestones", [:"query_#{query.id}"]]]
      variant.save!
      create(:relation, from: included, to: report)
      create(:relation, from: report, to: inaccessible)
    end

    it "includes only the visible work packages directly linked to the report" do
      sections = described_class.new(report, current_user: user).export.fetch(:sections)

      expect(sections).to contain_exactly(
        hash_including(name: "Milestones", items: [hash_including(id: included.id.to_s, title: included.subject)])
      )
    end
  end
end
