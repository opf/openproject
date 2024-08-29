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

RSpec.describe Storages::Storages::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :storage }

    let!(:user) { create(:admin) }

    let(:instance) do
      described_class.new(user:,
                          contract_class:)
    end

    let(:call_attributes) do
      {
        name: "My storage",
        host: "https://example.org",
        provider_type: "Storages::NextcloudStorage"
      }
    end

    let!(:model_instance) do
      build_stubbed(factory,
                    creator: user,
                    name: call_attributes[:name],
                    host: call_attributes[:host],
                    provider_type: call_attributes[:provider_type])
    end

    it "creates an OAuth application (::Doorkeeper::Application)" do
      expect(subject).to be_success
      expect(subject.result.oauth_application).to be_a(Doorkeeper::Application)
      expect(subject.result.oauth_application.name).to include call_attributes[:name]
      expect(subject.result.oauth_application.redirect_uri).to include call_attributes[:host]
      expect(subject.result.oauth_application.owner).to eql user
      expect(subject.result.oauth_application.plaintext_secret).to be_present
    end
  end
end
