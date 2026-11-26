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

RSpec.describe "Previewing a variant switch of a work package type's projects", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type: bug, variant_name: "Firmware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:forge) { create(:project, name: "Forge", types: [hardware]) }

  let(:user) { admin }
  let(:projects) { [foundry, forge] }
  let(:target) { firmware }

  before do
    create(:work_package, project: foundry, type: bug)
    create(:work_package, project: forge, type: bug)
    create(:work_package, project: bookshop, type: bug)
    login_as user
  end

  subject do
    post type_projects_switch_impact_path(type_id: bug.id),
         params: { project_ids: projects.map(&:id), target_id: target.id },
         as: :turbo_stream
  end

  it "previews the impact across the projects sharing a variant" do
    subject

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("2 work packages will use the new configuration")
  end

  context "with the variant in use" do
    let(:target) { hardware }

    it "previews nothing" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("will use the new configuration")
    end
  end

  context "with another type's variant" do
    let(:target) { create(:type).default_variant }

    it "previews nothing" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("will use the new configuration")
    end
  end

  context "with projects on different variants" do
    let(:projects) { [bookshop, foundry] }

    it "previews nothing" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("will use the new configuration")
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }

    it "is refused" do
      subject

      expect(response).to have_http_status(:forbidden)
    end
  end
end
