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

require_relative '../../spec_helper'

RSpec.describe Storages::Common::ConfigurationChecks do
  describe '.configured' do
    let!(:configured_storage) do
      storage = create(:storage)
      create(:oauth_application, integration: storage)
      create(:oauth_client, integration: storage)
      storage
    end
    let!(:unconfigured_storage) { create(:storage) }

    it 'returns only storages with complete configuration' do
      configured_storage_model = configured_storage.provider_type.constantize.find(configured_storage.id)
      unconfigured_storage_model = unconfigured_storage.provider_type.constantize.find(unconfigured_storage.id)

      expect(Storages::Storage.configured).to contain_exactly(configured_storage_model)
      expect(Storages::Storage.configured).not_to include(unconfigured_storage_model)
    end
  end

  describe '#configured?' do
    context 'with a complete configuration' do
      let(:storage) do
        build_stubbed(:storage,
                      oauth_application: build_stubbed(:oauth_application),
                      oauth_client: build_stubbed(:oauth_client))
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
      let(:storage) { build_stubbed(:storage, host: nil, name: nil) }

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
      let(:storage) { build_stubbed(:storage) }

      it 'returns false' do
        expect(storage.configured?).to be(false)

        aggregate_failures 'configuration_checks' do
          expect(storage.configuration_checks[:openproject_oauth_application_configured]).to be(false)
          expect(storage.configuration_checks[:storage_oauth_client_configured]).to be(false)
        end
      end
    end
  end
end
