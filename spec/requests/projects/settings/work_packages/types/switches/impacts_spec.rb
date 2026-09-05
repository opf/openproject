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

require "spec_helper"

RSpec.describe "Type variant switch impact",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:delivery) { create(:type_variant, type: epic, variant_name: "Delivery") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:bug_variant) { create(:type_variant, type: bug, variant_name: "Regression") }

  shared_let(:project) { create(:project, types: [epic]) }

  before do
    login_as admin

    epic.default_variant.update!(attribute_groups: [["Details", %w[assignee]]])
    delivery.update!(attribute_groups: [["Details", %w[priority]]])
    bug_variant.update!(attribute_groups: [["Details", %w[responsible]]])
  end

  def request_impact(target)
    post project_settings_work_packages_type_switch_impact_path(project, epic),
         params: { target_id: target.id },
         as: :turbo_stream
  end

  it "reports on another variant of the same type" do
    request_impact(delivery)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fields that will no longer be shown")
  end

  it "reports nothing for the variant the project already applies" do
    request_impact(epic.default_variant)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Fields that will no longer be shown")
  end

  # The select only offers members of this type, so this is only reachable by forging the
  # request. It has to answer the same way the switch itself does, which refuses the pair
  # with :switch_target_not_in_family rather than describing it.
  it "reports nothing for a variant of another type" do
    request_impact(bug_variant)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Fields that will no longer be shown")
  end
end
