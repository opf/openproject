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

RSpec.describe PlaceholderUsers::DeleteService do
  let(:placeholder_user) { create(:placeholder_user) }
  let(:actor) { create(:admin) }

  subject(:result) { described_class.new(model: placeholder_user, user: actor).call }

  context "when the placeholder user is used in a resource allocation" do
    before { create(:resource_allocation, placeholder_user:, principal: nil) }

    it "keeps the placeholder user active and does not schedule its deletion" do
      expect { result }.not_to have_enqueued_job(Principals::DeleteJob)

      expect(result).to be_failure
      expect(result.errors.details[:base]).to include(error: :used_in_resource_allocations)
      expect(placeholder_user.reload).to be_active
    end
  end

  context "when the placeholder user is not used in any resource allocation" do
    it "schedules its deletion" do
      expect { result }.to have_enqueued_job(Principals::DeleteJob).with(placeholder_user)

      expect(result).to be_success
      expect(placeholder_user.reload.status).to eq("deleted")
    end
  end
end
