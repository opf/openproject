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

require "rails_helper"

RSpec.describe TimeEntries::TimeEntryFormComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:, subject: "Plan the conference") }
  let(:time_entry) { build(:time_entry, entity: work_package, project:, user: build_stubbed(:user)) }

  current_user { build_stubbed(:admin) }

  subject(:rendered_component) do
    render_inline(described_class.new(time_entry:, show_work_package: false, show_user: false))
  end

  context "when the dialog is fixed on a work package" do
    it "shows the work package in a disabled field" do
      expect(rendered_component).to have_field("Work package", with: "#{work_package.formatted_id} Plan the conference",
                                                               disabled: true)
    end

    it "still submits the work package" do
      expect(rendered_component).to have_field("time_entry[entity_id]", with: work_package.id.to_s, type: :hidden)
    end
  end
end
