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

RSpec.describe CustomFields::DeleteService, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:admin) { create(:admin) }
  shared_let(:editor) { create(:admin) }

  let(:project) { create(:project) }
  let(:project_without_value) { create(:project) }
  let(:custom_field) { create(:string_project_custom_field, projects: [project, project_without_value]) }
  let(:custom_field_key) { "custom_fields_#{custom_field.id}" }

  subject(:service_call) { described_class.new(user: admin, model: custom_field).call }

  before do
    User.execute_as(editor) do
      project.update!(custom_field_values: { custom_field.id => "10" })
    end
  end

  current_user { admin }

  it "journals the removed value on the projects that had one, credited to the deleting user" do
    expect { service_call }.to change { project.journals.count }.by(1)

    expect(project.last_journal.user).to eq(admin)
    expect(project.last_journal.details).to include(custom_field_key => ["10", nil])
  end

  it "does not journal projects without a value for the field" do
    expect { service_call }.not_to change { project_without_value.journals.count }
  end

  it "does not attribute the removal to the next change of the project" do
    service_call

    User.execute_as(editor) do
      project.reload.update!(name: "Renamed")
    end

    expect(project.last_journal.details).to include("name")
    expect(project.last_journal.details).not_to have_key(custom_field_key)
  end
end
