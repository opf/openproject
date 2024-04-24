# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::OpenFileLinkQuery do
  let(:storage) { create(:nextcloud_storage, host: "https://example.com") }
  let(:user) { create(:user) }
  let(:file_id) { "1337" }

  it "responds to .call" do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq file_id], %i[key open_location])
  end

  it "returns the url for opening the file on storage" do
    url = described_class.call(storage:, user:, file_id:).result
    expect(url).to eq("#{storage.host}/index.php/f/#{file_id}?openfile=1")
  end

  it "returns the url for opening the file's location on storage" do
    url = described_class.call(storage:, user:, file_id:, open_location: true).result
    expect(url).to eq("#{storage.host}/index.php/f/#{file_id}?openfile=0")
  end

  context "with a storage with host url with a sub path" do
    let(:storage) { create(:nextcloud_storage, host: "https://example.com/html") }

    it "returns the url for opening the file on storage" do
      url = described_class.call(storage:, user:, file_id:).result
      expect(url).to eq("#{storage.host}/index.php/f/#{file_id}?openfile=1")
    end
  end
end
