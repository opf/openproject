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
require_relative "shared_examples"

RSpec.describe OAuth::Applications::BaseContract, type: :model do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user) { create(:admin) }

  subject { described_class.new(application, user).validate }

  describe ":user" do
    let(:application) { create(:oauth_application) }

    context "if user is admin" do
      it_behaves_like "oauth application contract is valid"
    end

    context "if user is not admin" do
      let(:user) { create(:user) }

      it_behaves_like "oauth application contract is invalid"
    end
  end

  describe ":integration" do
    context "if only integration id and not integration type is given" do
      let(:application) { create(:oauth_application, integration_id: 1) }

      it_behaves_like "oauth application contract is invalid"
    end

    context "if only integration type and not integration id is given" do
      let(:application) { create(:oauth_application, integration_type: "Storages::NextcloudStorage") }

      it_behaves_like "oauth application contract is invalid"
    end

    context "if both integration type and integration id is given" do
      let(:storage) { create(:nextcloud_storage) }
      let(:application) { create(:oauth_application, integration: storage) }

      it_behaves_like "oauth application contract is valid"
    end
  end

  describe ":client_credentials_user_id" do
    let(:secret) { "my_secret" }

    context "if no client credential user is defined" do
      let(:application) { build_stubbed(:oauth_application, secret:) }

      it_behaves_like "oauth application contract is valid"
    end

    context "if client credential user is defined and present" do
      let(:auth_user) { create(:user) }
      let(:application) { build_stubbed(:oauth_application, secret:, client_credentials_user_id: auth_user.id) }

      it_behaves_like "oauth application contract is valid"
    end

    context "if client credential user is defined and not present" do
      let(:application) { build_stubbed(:oauth_application, secret:, client_credentials_user_id: "1337") }

      it_behaves_like "oauth application contract is invalid"
    end
  end
end
