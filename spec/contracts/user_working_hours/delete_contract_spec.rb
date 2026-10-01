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
require "contracts/shared/model_contract_shared_context"

RSpec.describe UserWorkingHours::DeleteContract do
  include_context "ModelContract shared context"

  let(:target_user) { build_stubbed(:user) }
  let(:current_user) { build_stubbed(:user) }
  let(:working_hours) { build_stubbed(:user_working_hours, user: target_user) }
  let(:contract) { described_class.new(working_hours, current_user) }

  context "with global manage_working_times permission" do
    let(:current_user) { build_stubbed(:user) }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_globally(:manage_working_times)
      end
    end

    it_behaves_like "contract is valid"
  end

  context "with manage_own_working_times and owning the record" do
    let(:current_user) { target_user }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_globally(:manage_own_working_times)
      end
    end

    it_behaves_like "contract is valid"
  end

  context "with manage_own_working_times but not owning the record" do
    let(:current_user) { build_stubbed(:user) }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_globally(:manage_own_working_times)
      end
    end

    it_behaves_like "contract user is unauthorized"
  end

  context "without any relevant permissions" do
    let(:current_user) { build_stubbed(:user) }

    it_behaves_like "contract user is unauthorized"
  end

  include_examples "contract reuses the model errors"
end
