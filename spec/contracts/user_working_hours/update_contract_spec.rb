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

RSpec.describe UserWorkingHours::UpdateContract do
  include_context "ModelContract shared context"

  let(:target_user) { build_stubbed(:user) }
  let(:valid_from) { Date.tomorrow }
  let(:working_hours) { build_stubbed(:user_working_hours, user: target_user, valid_from:) }
  let(:contract) { described_class.new(working_hours, current_user) }
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_globally(:manage_working_times)
    end
  end

  context "when valid_from is in the future" do
    let(:valid_from) { Date.tomorrow }

    it_behaves_like "contract is valid"
  end

  context "when valid_from is today" do
    let(:valid_from) { Date.current }

    it_behaves_like "contract is valid"
  end

  context "when valid_from is in the past" do
    let(:valid_from) { Date.yesterday }

    it_behaves_like "contract is invalid", base: :not_editable
  end

  context "when valid_from was changed from today to future" do
    let(:valid_from) { Date.current }

    before do
      working_hours.valid_from = Date.tomorrow
    end

    it_behaves_like "contract is valid"
  end

  context "when valid_from was changed from past to future" do
    let(:valid_from) { Date.yesterday }

    before do
      working_hours.valid_from = Date.tomorrow
    end

    it_behaves_like "contract is invalid", base: :not_editable
  end

  context "without manage_working_times or manage_own_working_times permission" do
    before do
      mock_permissions_for(current_user) do |mock|
        # no permissions granted
      end
    end

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with manage_own_working_times and owning the record" do
    let(:current_user) { target_user }
    let(:valid_from) { Date.tomorrow }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_globally(:manage_own_working_times)
      end
    end

    it_behaves_like "contract is valid"
  end

  context "with manage_own_working_times but not owning the record" do
    let(:valid_from) { Date.tomorrow }

    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_globally(:manage_own_working_times)
      end
    end

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "when the user is changed" do
    before do
      working_hours.user = build_stubbed(:user)
    end

    it_behaves_like "contract is invalid", user_id: :error_readonly
  end

  include_examples "contract reuses the model errors"
end
