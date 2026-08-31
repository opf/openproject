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

module Storages
  module Adapters
    module AuthenticationStrategies
      RSpec.describe BearerToken do
        let(:storage) { create(:nextcloud_storage) }
        let(:access_token) { "my_access_token" }

        it "must yield with the passed access token" do
          strategy = Input::Strategy.build(key: :bearer_token, token: access_token)
          was_yielded = false

          Authentication[strategy].call(storage:) do |http|
            was_yielded = true
            expect(http.instance_variable_get(:@options).auth_header_type).to eq("Bearer")
            expect(http.instance_variable_get(:@options).auth_header_value).to eq(access_token)
          end

          expect(was_yielded).to be_truthy
        end
      end
    end
  end
end
