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
require_relative "shared_contract_examples"

RSpec.describe Storages::Storages::CreateContract do
  it_behaves_like "nextcloud storage contract" do
    let(:storage) do
      build_stubbed(:nextcloud_storage,
                    creator: storage_creator,
                    host: storage_host,
                    name: storage_name,
                    provider_type: storage_provider_type)
    end
    let(:contract) { described_class.new(storage, current_user) }

    context "when creator is not the current user" do
      let(:storage_creator) { build_stubbed(:user) }

      include_examples "contract is invalid", creator: :invalid
    end
  end
end
