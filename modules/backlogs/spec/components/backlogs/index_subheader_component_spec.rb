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

RSpec.describe Backlogs::IndexSubheaderComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  let(:query) { Query.new(project:, user:) }

  subject(:component) { described_class.new(query:, project:) }

  before do
    vc_test_controller.request.path_parameters = {
      controller: "backlogs/filters", action: "show", project_id: project.id.to_s
    }
  end

  describe "#filter_input_value" do
    it "is nil when no subject filter is active" do
      expect(component.filter_input_value).to be_nil
    end

    it "returns the active subject filter's value" do
      query.add_filter(:subject, "~", ["foo"])

      expect(component.filter_input_value).to eq("foo")
    end
  end

  describe "#filters_expanded?" do
    it "is false without any active filter" do
      render_inline(component)

      expect(component.filters_expanded?).to be false
    end

    it "is false when only filters controlled by dedicated pickers are active" do
      query.add_filter(:subject, "~", ["foo"])
      render_inline(component)

      expect(component.filters_expanded?).to be false
    end

    it "is true when an advanced filter is active" do
      query.add_filter(:status_id, "o", [""])
      render_inline(component)

      expect(component.filters_expanded?).to be true
    end
  end

  it "renders the permanent subject quick search field" do
    render_inline(component)

    expect(page).to have_css("[data-filter-name='subject']")
  end
end
