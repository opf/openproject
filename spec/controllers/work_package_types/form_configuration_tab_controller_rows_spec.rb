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

RSpec.describe WorkPackageTypes::FormConfigurationTabController do
  let(:type) { create(:type) }
  let(:user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(user)
    type.update_column(:attribute_groups, [[:details, %w[priority version]]])
  end

  describe "PUT #drop", with_ee: %i[edit_attribute_groups] do
    it "uses the row_key param and moves the row to inactive" do
      put :drop,
          params: { type_id: type.id, row_key: "priority", target_id: "inactive", position: 1 },
          format: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(type.reload.attribute_groups.flat_map(&:members)).not_to include("priority")
    end

    it "moves the row into another active section at the requested position" do
      type.update_column(:attribute_groups, [
                           [:details, %w[priority]],
                           ["Custom group", %w[version]]
                         ])

      put :drop,
          params: { type_id: type.id, row_key: "priority", target_id: "Custom group", position: 1 },
          format: :turbo_stream

      expect(response).to have_http_status(:ok)

      target_group = type.reload.attribute_groups.find { |group| group.key == "Custom group" }
      expect(target_group.members).to eq(%w[priority version])
    end
  end
end
