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

RSpec.describe Storages::Nextcloud::ConfigurationCompletionChecks do
  describe '#configuration_complete?' do
    context 'with a complete configuration' do
      let(:storage) do
        storage_ = create(:nextcloud_storage, :as_not_automatically_managed)
        create(:oauth_application, integration: storage_)
        create(:oauth_client, integration: storage_)
        storage_
      end

      it 'returns true' do
        expect(storage.configuration_complete?).to be(true)

        aggregate_failures 'configuration_completion_checks' do
          expect(storage.configuration_completion_checks)
            .to eq(host_name_configured: true,
                   nextcloud_application_credentials_configured: true,
                   nextcloud_automatically_managed_project_folders_configured: true,
                   openproject_application_credentials_configured: true)
        end
      end
    end

    context 'without host name' do
      let(:storage) { build(:nextcloud_storage, host: nil, name: nil) }

      it 'returns false' do
        aggregate_failures do
          expect(storage.configuration_complete?).to be(false)
          aggregate_failures 'configuration_completion_checks' do
            expect(storage.configuration_completion_checks[:host_name_configured]).to be(false)
          end
        end
      end
    end

    context 'without openproject and nextcloud integrations' do
      let(:storage) { build(:nextcloud_storage, :as_not_automatically_managed) }

      it 'returns false' do
        expect(storage.configuration_complete?).to be(false)

        aggregate_failures 'configuration_completion_checks' do
          expect(storage.configuration_completion_checks[:openproject_application_credentials_configured]).to be(false)
          expect(storage.configuration_completion_checks[:nextcloud_application_credentials_configured]).to be(false)
        end
      end
    end

    context 'without automatic project folder configuration' do
      let(:storage) { build(:nextcloud_storage) }

      it 'returns false' do
        expect(storage.configuration_complete?).to be(false)

        aggregate_failures 'configuration_completion_checks' do
          expect(storage.configuration_completion_checks[:nextcloud_automatically_managed_project_folders_configured])
            .to be(false)
          expect(storage.automatic_management_unspecified?).to be(true)
        end
      end
    end
  end
end
