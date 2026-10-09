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

RSpec.describe "projects/settings/general/show" do
  include TestSelectorFinders

  let(:project) { build_stubbed(:project, public:) }
  let(:user) { build_stubbed(:admin) }

  before do
    assign(:project, project)

    without_partial_double_verification do
      allow(view)
        .to receive(:current_user)
        .and_return(user)
    end

    render
  end

  context "when project is not public" do
    let(:public) { false }

    it "does not show warning banner" do
      expect(rendered).not_to have_test_selector "op-projects-public-warning"
    end
  end

  context "when project is public" do
    let(:public) { true }

    it "shows warning banner" do
      expect(rendered).to have_test_selector "op-projects-public-warning"
    end
  end
end
