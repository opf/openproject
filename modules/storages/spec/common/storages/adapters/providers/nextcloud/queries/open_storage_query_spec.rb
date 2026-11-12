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
          RSpec.describe OpenStorageQuery do
            let(:storage) { create(:nextcloud_storage, host: "https://example.com") }

            it "responds to .call" do
              expect(described_class).to respond_to(:call)

              method = described_class.method(:call)
              expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq input_data])
            end

            it "returns the url for opening the file on storage" do
              url = described_class.call(storage:, auth_strategy: nil, input_data: nil).value!
              expect(url).to eq("#{storage.host}/index.php/apps/files")
            end

            context "with a storage with host url with a sub path" do
              let(:storage) { create(:nextcloud_storage, host: "https://example.com/html") }

              it "returns the url for opening the file on storage" do
                url = described_class.call(storage:, auth_strategy: nil, input_data: nil).value!
                expect(url).to eq("#{storage.host}/index.php/apps/files")
              end
            end
          end
        end
      end
    end
  end
end
