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

require "rails_helper"

RSpec.describe Backlogs::Sprints::TableComponent, type: :component do
  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:) }
  let(:other_sprint) { create(:sprint, project:) }
  let(:work_package_counts) do
    {
      sprint.id => 2,
      other_sprint.id => 4
    }
  end

  subject(:rendered_component) do
    render_inline(described_class.new(rows: sprints, project:, work_package_counts:))
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Sprint name"
    include_examples "rendering Border Box Grid heading", text: "Status"
    include_examples "rendering Border Box Grid heading", text: "Start date"
    include_examples "rendering Border Box Grid heading", text: "Finish date"
    include_examples "rendering Border Box Grid heading", text: "Work packages"
    include_examples "rendering Border Box Grid mobile heading", text: "All sprints"
  end

  context "with no sprints" do
    let(:sprints) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "Nothing to display"
  end

  context "with sprints" do
    let(:sprints) { [sprint, other_sprint] }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 5
  end
end
