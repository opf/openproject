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
require "contracts/shared/model_contract_shared_context"

RSpec.describe UserPreferences::UpdateContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:preference_user) { current_user }
  let(:user_preference) do
    build_stubbed(:user_preference, user: preference_user).tap do |pref|
      pref.assign_attributes(attributes)
    end
  end
  let(:attributes) do
    {
      auto_hide_popups: true,
      comments_sorting: "desc",
      daily_reminders_enabled: true,
      daily_reminders_times: %w[08:00:00+00:00 12:00:00+00:00],
      time_zone: "America/Sao_Paulo",
      warn_on_leaving_unsaved: true,
      disable_keyboard_shortcuts: true,
      require_double_click_for_inline_edit: true,
      workdays: [1, 2, 4, 6]
    }
  end
  let(:contract) { described_class.new(user_preference, current_user) }

  describe "validation" do
    context "when current_user is admin" do
      let(:current_user) { build_stubbed(:admin) }
      let(:preference_user) { build_stubbed(:user) }

      it_behaves_like "contract is valid"
    end

    context "when current_user has manage_user permission" do
      let(:preference_user) { build_stubbed(:user) }

      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_globally(:manage_user)
        end
      end

      it_behaves_like "contract is valid"
    end

    context "when current_user is the own user" do
      it_behaves_like "contract is valid"
    end

    context "when current_user is the own user but not active" do
      before do
        allow(current_user).to receive(:active?).and_return false
      end

      it_behaves_like "contract user is unauthorized"
    end

    context "when current_user is anonymous" do
      let(:current_user) { User.anonymous }

      it_behaves_like "contract user is unauthorized"
    end

    context "when current_user is a regular user" do
      let(:preference_user) { build_stubbed(:user) }

      it_behaves_like "contract user is unauthorized"
    end

    context "with an invalid preference value" do
      let(:attributes) { { comments_sorting: "up" } }

      it_behaves_like "contract is invalid", comments_sorting: :inclusion
    end

    context "when changing the user of a persisted preference" do
      let(:attributes) { { user_id: preference_user.id + 1 } }

      it_behaves_like "contract is invalid", user_id: :error_readonly
    end
  end

  include_examples "contract reuses the model errors"
end
