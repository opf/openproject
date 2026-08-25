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

RSpec.describe Backlogs::BacklogFiltersComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }
  # StatusFilter#available? checks Status.all.any? -- without at least one
  # status in the DB it's excluded from available_advanced_filters entirely.
  shared_let(:status) { create(:status) }

  current_user { user }

  let(:query) do
    Query.new(project:, user:).tap do |q|
      q.add_filter(:sprint_id, "=", [sprint.id.to_s])
      q.add_filter(:backlog_bucket_id, "=", [backlog_bucket.id.to_s])
      q.add_filter(:backlog_inbox, "=", [OpenProject::Database::DB_VALUE_TRUE])
      q.add_filter(:status_id, "o", [""])
    end
  end

  subject(:component) { described_class.new(query:) }

  # The component's form rendering relies on the current page via
  # primer_form_with(url: {}, ...). Setting up the current route explcitly,
  # because vc_test_controller doesn't have one by default.
  before do
    vc_test_controller.request.path_parameters = {
      controller: "backlogs/filters", action: "show", project_id: project.id.to_s
    }
  end

  describe "#allowed_filters" do
    it "still includes generic work package attribute filters" do
      names = component.allowed_filters.map(&:name)

      expect(names).to include(:status_id)
    end
  end

  describe "#turbo_requests?" do
    it "is true, so the panel live-updates without an Apply/Close footer" do
      expect(component.turbo_requests?).to be true
    end
  end

  it "renders the generic filters, but not the ones controlled by the dedicated picker" do
    render_inline(component)

    expect(page).to have_css("[data-filter-name='status_id']")
    expect(page).to have_no_css("[data-filter-name='sprint_id']")
    expect(page).to have_no_css("[data-filter-name='backlog_bucket_id']")
    expect(page).to have_no_css("[data-filter-name='backlog_inbox']")
  end
end
