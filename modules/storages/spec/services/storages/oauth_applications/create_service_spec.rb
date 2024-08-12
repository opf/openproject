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
require_module_spec_helper

require "services/base_services/behaves_like_create_service"

RSpec.describe Storages::OAuthApplications::CreateService, type: :model do
  let(:user) { create(:admin) }
  let(:storage) { create(:nextcloud_storage, creator: user) }
  let(:instance) { described_class.new(user:, storage:) }

  describe "#call" do
    subject { instance.call }

    it "returns a OAuthApplication" do
      expect(subject).to be_a ServiceResult
      expect(subject).to be_success
      expect(subject.result).to be_a Doorkeeper::Application
      expect(subject.result.name).to include storage.name
      expect(subject.result.name).to include I18n.t("storages.provider_types.#{storage.short_provider_type}.name")
      expect(subject.result.scopes.to_s).to eql "api_v3"
      expect(subject.result.redirect_uri).to include storage.host
      expect(subject.result.redirect_uri).to include "apps/integration_openproject/oauth-redirect"
      expect(subject.result.integration).to eql storage
      expect(subject.result.confidential).to be_truthy
      expect(subject.result.owner).to eql user
    end
  end
end
