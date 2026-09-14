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

RSpec.describe ResourceAllocations::ListComponent, type: :component do
  shared_let(:work_package) { create(:work_package) }
  shared_let(:member) { create(:user, firstname: "Sarah", lastname: "Smith") }

  before { login_as(create(:admin)) }

  subject(:rendered_component) do
    render_inline(
      described_class.new(
        project: work_package.project,
        work_package:,
        allocations:,
        visible_principal_ids: [member.id]
      )
    )
  end

  context "with allocations" do
    let!(:allocation) { create(:resource_allocation, entity: work_package, principal: member) }
    let(:allocations) { [allocation] }

    it_behaves_like "rendering Box", row_count: 1, header: false

    it "renders a row per allocation" do
      expect(rendered_component).to have_css(".Box-row", text: "Sarah Smith")
    end
  end

  context "without allocations" do
    let(:allocations) { [] }

    it "does not render the list box" do
      expect(rendered_component).to have_no_css("#resource-allocations-#{work_package.id}")
    end
  end
end
