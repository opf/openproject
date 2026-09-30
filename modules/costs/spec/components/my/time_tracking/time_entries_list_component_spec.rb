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

RSpec.describe My::TimeTracking::TimeEntriesListComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(rows: time_entries)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Hours"
    include_examples "rendering Border Box Grid heading", text: "Subject"
    include_examples "rendering Border Box Grid heading", text: "Project"
    include_examples "rendering Border Box Grid heading", text: "Activity"
    include_examples "rendering Border Box Grid heading", text: "Comment"
    include_examples "rendering Border Box Grid mobile heading", text: "Time entries"
  end

  context "with no time entries" do
    let(:time_entries) { create_list(:time_entry, 0) }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "Nothing to display"
  end

  context "with time entries" do
    let(:time_entries) { create_list(:time_entry, 2) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 5
  end
end
