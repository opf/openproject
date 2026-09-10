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

RSpec.describe Meetings::MeetingFiltersComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  let(:query) { Queries::Meetings::MeetingQuery.new(user:) }

  subject(:component) { described_class.new(query:, project:) }

  before do
    vc_test_controller.request.path_parameters = {
      controller: "meetings/filters", action: "show", project_id: project.id.to_s
    }
  end

  describe "#allowed_filters" do
    it "advertises the title filter" do
      expect(component.allowed_filters.map(&:name)).to include(:title)
    end
  end

  it "renders the title filter as a text input with the contains operators" do
    render_inline(component)

    expect(page).to have_css("[data-filter-name='title']", visible: :all)
    expect(page).to have_field("title_value", type: "text", visible: :all)

    operators = page.all("select[name='operator_title'] option", visible: :all).pluck(:value)
    expect(operators).to contain_exactly("~", "!~")
  end
end
