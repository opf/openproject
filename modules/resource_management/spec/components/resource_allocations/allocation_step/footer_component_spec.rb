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

RSpec.describe ResourceAllocations::AllocationStep::FooterComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:member) { create(:user) }
  shared_let(:allocation) { create(:resource_allocation, entity: work_package, principal: member) }

  subject(:rendered) do
    render_inline(described_class.new(**args))
    page
  end

  context "without an allocation (the create wizard)" do
    let(:args) { {} }

    before { login_as(create(:admin)) }

    it "renders Cancel and Save but no Delete button" do
      expect(rendered).to have_button(I18n.t(:button_cancel))
      expect(rendered).to have_no_css("a[data-turbo-method='delete']")
    end
  end

  context "when editing a persisted allocation" do
    let(:args) { { allocation: } }

    context "and the user may allocate" do
      before do
        login_as(create(:user, member_with_permissions: {
                          project => %i[view_resource_planners allocate_user_resources]
                        }))
      end

      it "renders a Delete button targeting the destroy path" do
        expect(rendered).to have_css(
          "a[data-turbo-method='delete'][href$='/resource_allocations/#{allocation.id}']",
          text: I18n.t(:button_delete)
        )
      end
    end

    context "and the user may not allocate" do
      before do
        login_as(create(:user, member_with_permissions: { project => %i[view_resource_planners] }))
      end

      it "hides the Delete button" do
        expect(rendered).to have_no_css("a[data-turbo-method='delete']")
      end
    end
  end
end
