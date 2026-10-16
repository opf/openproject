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
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::Admin::StorageAudienceInfoComponent, type: :component do
  let(:storage) { create(:nextcloud_storage, storage_audience:) }
  let(:storage_audience) { "Alice" }

  subject(:render_component) do
    render_inline(described_class.new(storage))
  end

  it "presents a component title of 'Storage Audience'", :aggregate_failures do
    render_component

    expect(page).to have_test_selector("storage-audience-label")
    expect(page).to have_content("Token Exchange")
  end

  it "indicates the name of the selected audience" do
    render_component
    expect(page).to have_content('Exchanging tokens for audience "Alice".')
  end

  context "when audience is empty string" do
    let(:storage_audience) { "" }

    it "indicates that no audience has been selected" do
      render_component
      expect(page).to have_content("No audience has been configured.")
    end
  end

  context "when audience is nil" do
    let(:storage_audience) { nil }

    it "indicates that no audience has been selected" do
      render_component
      expect(page).to have_content("No audience has been configured.")
    end
  end

  context "when audience is the magic value for the IDP audience" do
    let(:storage_audience) { OpenIDConnect::UserToken::IDP_AUDIENCE }

    it "indicates that the IDP audience has been selected" do
      render_component
      expect(page).to have_content("Using access token obtained by identity provider during login, regardless of audience.")
    end
  end
end
