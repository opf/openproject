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
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Queries
          RSpec.describe OpenFileLinkQuery do
            let(:storage) { create(:nextcloud_storage, host: "https://example.com") }
            let(:auth_strategy) { Registry["nextcloud.authentication.userless"].call }
            let(:file_id) { "1337" }
            let(:open_location) { false }
            let(:input_data) { Input::OpenFileLink.build(file_id:, open_location:).value! }
            let(:open_file_link) { "#{storage.host}/index.php/f/#{file_id}?openfile=#{open_location ? '0' : '1'}" }

            it_behaves_like "storage adapter: query call signature", "open_file_link"

            context "with open location flag not set" do
              it_behaves_like "adapter open_file_link_query: successful link response"
            end

            context "with open location flag set" do
              let(:open_location) { true }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end

            context "with a storage with host url with a sub path" do
              let(:storage) { create(:nextcloud_storage, host: "https://example.com/html") }

              it_behaves_like "adapter open_file_link_query: successful link response"
            end
          end
        end
      end
    end
  end
end
