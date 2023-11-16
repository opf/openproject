# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_relative 'shared_base_storage_spec'
require_module_spec_helper

RSpec.describe Storages::NextcloudStorage do
  let(:storage) { create(:nextcloud_storage) }

  it_behaves_like 'base storage'

  describe '#provider_type?' do
    it { expect(storage).to be_a_provider_type_nextcloud }
    it { expect(storage).not_to be_a_provider_type_one_drive }
  end

  describe '#mark_as_unhealthy' do
    it 'fills health atrributes in' do
      Timecop.freeze('2023-03-14T15:17:00Z') do
        expect do
          storage.mark_as_unhealthy(reason: 'thou_shall_not_pass_error')
        end.to(
          change(storage, :health_changed_at).from(nil).to(Time.now.utc)
            .and(change(storage, :health_status).from(nil).to('unhealthy'))
            .and(change(storage, :health_reason).from(nil).to('thou_shall_not_pass_error'))
        )
      end
    end
  end

  describe '#mark_as_healthy' do
    before do
      Timecop.freeze('2021-03-14T15:17:00Z') do
        storage.mark_as_unhealthy(reason: 'just nope')
      end
    end

    it 'fills health atrributes in' do
      Timecop.freeze('2023-03-14T15:17:00Z') do
        expect do
          storage.mark_as_healthy
        end.to(
          change(storage, :health_changed_at).from(Time.parse('2021-03-14T15:17:00Z')).to(Time.now.utc)
            .and(change(storage, :health_status).from('unhealthy').to('healthy'))
            .and(change(storage, :health_reason).from('just nope').to(nil))
        )
      end
    end
  end

  describe '#configured?' do
    context 'with a complete configuration' do
      let(:storage) do
        build(:nextcloud_storage,
              oauth_application: build(:oauth_application),
              oauth_client: build(:oauth_client))
      end

      it 'returns true' do
        expect(storage.configured?).to be(true)

        aggregate_failures 'configuration_checks' do
          expect(storage.configuration_checks)
            .to eq(host_name_configured: true,
                   storage_oauth_client_configured: true,
                   openproject_oauth_application_configured: true)
        end
      end
    end

    context 'without host name' do
      let(:storage) { build(:nextcloud_storage, host: nil, name: nil) }

      it 'returns false' do
        aggregate_failures do
          expect(storage.configured?).to be(false)
          aggregate_failures 'configuration_checks' do
            expect(storage.configuration_checks[:host_name_configured]).to be(false)
          end
        end
      end
    end

    context 'without openproject and storage integrations' do
      let(:storage) { build(:nextcloud_storage) }

      it 'returns false' do
        expect(storage.configured?).to be(false)

        aggregate_failures 'configuration_checks' do
          expect(storage.configuration_checks[:openproject_oauth_application_configured]).to be(false)
          expect(storage.configuration_checks[:storage_oauth_client_configured]).to be(false)
        end
      end
    end
  end

  shared_examples 'a stored attribute with default value' do |attribute, default_value|
    context "when the provider fields are empty" do
      let(:storage) { build(:nextcloud_storage, provider_fields: {}) }

      it "has a default runtime value of #{default_value}" do
        expect(storage.provider_fields).to eq({})
        expect(storage.public_send(attribute)).to eq(default_value)
      end
    end

    context "with a new value of 'foo'" do
      it "sets the value to 'foo'" do
        storage.public_send("#{attribute}=", 'foo')
        expect(storage.public_send(attribute)).to eq('foo')
      end
    end
  end

  shared_examples 'a stored boolean attribute' do |attribute|
    it "#{attribute} has a default value of false" do
      expect(storage.public_send(:"#{attribute}?")).to be(false)
    end

    ['1', 'true', true].each do |boolean_like|
      context "with truthy value #{boolean_like}" do
        it "sets #{attribute} to true" do
          storage.public_send(:"#{attribute}=", boolean_like)
          expect(storage.public_send(attribute)).to be(true)
        end
      end
    end

    it "#{attribute} can be set to true" do
      storage.public_send(:"#{attribute}=", true)

      expect(storage.public_send(attribute)).to be(true)
      expect(storage.public_send(:"#{attribute}?")).to be(true)
    end
  end

  describe '#username' do
    it_behaves_like 'a stored attribute with default value', :username, 'OpenProject'
  end

  describe '#group' do
    it_behaves_like 'a stored attribute with default value', :group, 'OpenProject'
  end

  describe '#group_folder' do
    it_behaves_like 'a stored attribute with default value', :group_folder, 'OpenProject'
  end

  describe '#automatically_managed?' do
    it_behaves_like 'a stored boolean attribute', :automatically_managed
  end

  describe '#automatic_management_unspecified?' do
    context 'when automatically_managed is nil' do
      let(:storage) { build(:nextcloud_storage, automatically_managed: nil) }

      it { expect(storage).to be_automatic_management_unspecified }
    end

    context 'when automatically_managed is true' do
      let(:storage) { build(:nextcloud_storage, automatically_managed: true) }

      it { expect(storage).not_to be_automatic_management_unspecified }
    end

    context 'when automatically_managed is false' do
      let(:storage) { build(:nextcloud_storage, automatically_managed: false) }

      it { expect(storage).not_to be_automatic_management_unspecified }
    end
  end

  describe '#provider_fields_defaults' do
    let(:storage) { build(:nextcloud_storage) }

    it 'returns the default values for nextcloud' do
      expect(storage.provider_fields_defaults).to eq({ automatically_managed: true, username: 'OpenProject' })
    end
  end
end
