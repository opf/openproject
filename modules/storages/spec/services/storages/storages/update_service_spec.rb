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

require "services/base_services/behaves_like_update_service"

RSpec.describe Storages::Storages::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :nextcloud_storage }
    let!(:user) { create(:admin) }

    let(:instance) do
      described_class.new(user:,
                          model: model_instance,
                          contract_class:)
    end

    let(:call_attributes) do
      {
        name: "My updated storage",
        host: "https://new.example.org"
      }
    end

    let!(:model_instance) do
      build_stubbed(factory,
                    creator: user,
                    name: "My updated storage",
                    host: "https://updated.example.org")
    end

    let!(:oauth_application) { create(:oauth_application, integration: model_instance) }

    it "creates an OAuth application (::Doorkeeper::Application)" do
      expect(subject).to be_success
      expect(subject.result.oauth_application).to be_a(Doorkeeper::Application)
      expect(subject.result.oauth_application.name).to include "My updated storage"
      expect(subject.result.oauth_application.redirect_uri).to include "https://updated.example.org"
    end
  end

  it "cannot update storage creator" do
    storage_creator = create(:admin, login: "storage_creator")
    storage = create(:nextcloud_storage, creator: storage_creator)
    service = described_class.new(user: create(:admin),
                                  model: storage)

    service_result = service.call(creator: create(:user, login: "impostor"))

    expect(service_result).to be_failure
    expect(service_result.errors.symbols_for(:creator_id)).to contain_exactly(:error_readonly)
    expect(storage.reload.creator).to eq(storage_creator)
  end

  describe "updates the nested OAuth application" do
    let(:storage) { create(:nextcloud_storage) }
    let!(:oauth_application) { create(:oauth_application, integration: storage) }
    let(:user) { create(:admin) }
    let(:name) { "Awesome Storage" }

    subject do
      described_class
        .new(user:, model: storage)
        .call({ name: })
    end

    it "must update the name of the OAuth application" do
      expect(subject.result.oauth_application.name).to eq("Awesome Storage (Nextcloud)")
    end
  end
end
