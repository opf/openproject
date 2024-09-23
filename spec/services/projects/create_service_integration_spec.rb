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

RSpec.describe Projects::CreateService, "integration", type: :model do
  let(:instance) { described_class.new(user:) }
  let(:new_project) { service_result.result }
  let(:service_result) { instance.call(**attributes) }

  before do
    login_as(user)
  end

  describe "writing created_at timestamp" do
    shared_let(:user) { create(:admin) }

    let(:created_at) { 11.days.ago }

    let(:attributes) do
      {
        name: "test",
        created_at:
      }
    end

    context "when enabled", with_settings: { apiv3_write_readonly_attributes: true } do
      it "updates the timestamps correctly" do
        expect(service_result)
          .to be_success

        new_project.reload
        expect(new_project.created_at).to equal_time_without_usec(created_at)
      end
    end

    context "when disabled", with_settings: { apiv3_write_readonly_attributes: false } do
      it "rejects the creation" do
        expect(service_result)
          .not_to be_success

        expect(new_project.errors.symbols_for(:created_at))
          .to contain_exactly(:error_readonly)
      end
    end
  end
end
