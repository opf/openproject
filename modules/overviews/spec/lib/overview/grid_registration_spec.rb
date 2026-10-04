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

RSpec.describe Overviews::GridRegistration do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:grid) { build_stubbed(:overview, project:) }

  describe "writable?" do
    let(:permissions) { %i[manage_dashboards view_project] }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *permissions, project:
      end
    end

    context "if the user has the :manage_dashboards permission" do
      it "is truthy" do
        expect(described_class)
          .to be_writable(grid, user)
      end
    end

    context "if the user lacks the :manage_dashboards permission and it is a persisted page" do
      let(:permissions) { %i[view_project] }

      it "is falsey" do
        expect(described_class)
          .not_to be_writable(grid, user)
      end
    end

    context "if the user lacks the :manage_dashboards permission and it is a new record" do
      let(:permissions) { %i[view_project] }
      let(:grid) { Grids::Overview.new **attributes_for(:overview).merge(project:) }

      it "is truthy" do
        expect(described_class)
          .to be_writable(grid, user)
      end
    end
  end
end
