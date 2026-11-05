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

RSpec.describe TestManagement::Assistant::AI::ConnectionTest, "SSRF protection" do
  before { allow(OpenProject::Configuration).to receive(:ssrf_protection_ip_allowlist).and_return([]) }

  it "explains the allowlist for a private address" do
    merged, = TestManagement::Assistant::ProviderConfig.apply(
      {}, "assistant_provider" => "custom", "assistant_auth_style" => "none",
          "assistant_base_url" => "http://127.0.0.1:9/v1"
    )
    result = described_class.new(TestManagement::Assistant::ProviderConfig.new(merged)).call

    expect(result.error_kind).to eq(:ssrf)
  end
end
