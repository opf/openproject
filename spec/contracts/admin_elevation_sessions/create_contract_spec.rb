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

RSpec.describe AdminElevationSessions::CreateContract, with_flag: { admin_privilege_elevation: true } do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:project) { build_stubbed(:project) }
  let(:model) do
    AdminElevationSession.new(project:, session_id: "session", confirmed_with: "password").tap do |elevation_session|
      elevation_session.extend(OpenProject::ChangedBySystem)
      elevation_session.change_by_system do
        elevation_session.user = current_user
        elevation_session.last_used_at = Time.current
      end
    end
  end
  let(:contract) { described_class.new(model, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "with the feature flag inactive", :check_errors_i18n, with_flag: { admin_privilege_elevation: false } do
    include_examples "contract is invalid", base: :feature_disabled
  end

  context "with an archived project", :check_errors_i18n do
    let(:project) { build_stubbed(:project, active: false) }

    include_examples "contract is invalid", project: :archived
  end

  context "when confirmed by clicking" do
    before { model.confirmed_with = "confirmation" }

    context "for a user with a password", :check_errors_i18n do
      before { allow(current_user).to receive(:password_checkable?).and_return(true) }

      include_examples "contract is invalid", base: :password_required
    end

    context "for a user without a password" do
      before { allow(current_user).to receive(:password_checkable?).and_return(false) }

      include_examples "contract is valid"
    end
  end

  context "with the user being set by the caller" do
    let(:model) do
      AdminElevationSession.new(user: current_user, project:, session_id: "session", confirmed_with: "password")
    end

    include_examples "contract is invalid", user_id: :error_readonly
  end
end
