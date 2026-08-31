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
require "services/base_services/behaves_like_create_service"

RSpec.describe WorkPackageTypes::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :type }
    let(:model_class) { Type }
  end

  context "if another type is selected to copy the workflow from" do
    let(:user) { create(:admin) }
    let(:existing_type) { create(:type_with_workflow) }
    let(:params) do
      {
        name: "Order 66",
        copy_workflow_from: existing_type.id.to_s,
        is_milestone: false,
        is_in_roadmap: true
      }
    end

    it "copies the workflow to the newly created type" do
      service = described_class.new(user:)
      result = service.call(params)

      expect(result).to be_success
      expect(result.result.default_variant.workflows).not_to be_empty
    end
  end
end
