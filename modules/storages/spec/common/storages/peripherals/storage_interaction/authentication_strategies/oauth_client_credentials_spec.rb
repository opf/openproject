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

RSpec.describe Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials, :webmock do
  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:cache_key) { "storage.#{storage.id}.httpx_access_token" }

  subject(:strategy) { described_class.new(true) }

  context "when the attempted request fails with a 403" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/4d44bf36-9b56-45c0-8807-bbf386dd047f/oauth2/v2.0/token")
        .and_return(status: 200, body: token_json, headers: { content_type: "application/json" })

      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2OBb-brzKzZAR4DYT1k9KPXs/root")
        .and_return(status: 403)
    end

    it "does not cache the result" do
      expect(Rails.cache.fetch(cache_key)).to be_nil

      strategy.call(storage:) do |http|
        http.get("https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root").raise_for_status
      rescue HTTPX::Error
        ServiceResult.failure
      end

      expect(Rails.cache.fetch(cache_key)).to be_nil
    end

    it "returns the result of the operation" do
      result = strategy.call(storage:) do |http|
        http.get("https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root").raise_for_status
      rescue HTTPX::Error
        ServiceResult.failure(result: "It failed")
      end

      expect(result).to be_failure
      expect(result.result).to eq("It failed")
    end

    it "clears an already existing token" do
      Rails.cache.write(cache_key, "BORKED_TOKEN")

      strategy.call(storage:) do |http|
        http.get("https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root").raise_for_status
      rescue HTTPX::Error
        ServiceResult.failure(result: :forbidden)
      end

      expect(Rails.cache.fetch(cache_key)).to be_nil
    end
  end

  context "when the attempted request works" do
    before do
      Rails.cache.clear

      stub_request(:post, "https://login.microsoftonline.com/4d44bf36-9b56-45c0-8807-bbf386dd047f/oauth2/v2.0/token")
        .and_return(status: 200, body: token_json, headers: { content_type: "application/json" })

      stub_request(:get, "https://graph.microsoft.com/v1.0/drives/b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2OBb-brzKzZAR4DYT1k9KPXs/root")
        .and_return(status: 200, body: { data: "bunch of data" }.to_json, headers: { content_type: "application/json" })
    end

    it "caches the generated token" do
      expect(Rails.cache.fetch(cache_key)).to be_nil

      strategy.call(storage:) do |http|
        http.get("https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root").raise_for_status
        ServiceResult.success
      end

      expect(Rails.cache.fetch(cache_key)).to eq("TOTALLY_VALID_TOKEN")
    end

    it "returns the result of the operation" do
      result = strategy.call(storage:) do |http|
        http.get("https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root").raise_for_status
        ServiceResult.success(result: "It works")
      end

      expect(result).to be_success
      expect(result.result).to eq("It works")
    end
  end

  private

  def token_json
    '{"token_type":"Bearer","expires_in":3599,"ext_expires_in":3599,"access_token":"TOTALLY_VALID_TOKEN"}'
  end
end
