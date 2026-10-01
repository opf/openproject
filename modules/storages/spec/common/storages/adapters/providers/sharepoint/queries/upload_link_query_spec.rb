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
    module Providers
      module Sharepoint
        module Queries
          RSpec.describe UploadLinkQuery, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }
            let(:upload_method) { :put }
            let(:input_data) { Input::UploadLink.build(folder_id:, file_name:).value! }
            let(:file_name) { "DeathStart_blueprints.tiff" }

            it_behaves_like "storage adapter: query call signature", "upload_link"

            context "when creating an upload link to the root folder of a list", vcr: "sharepoint/upload_link_success" do
              let(:folder_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK" }

              let(:token) do
                "v1.eyJzaXRlaWQiOiIxMDk5ZTMxNS1kMGM3LTQ3YzctODY0MC1hYTk1MDRiNzBmZmYiLCJhcHBfZGlzcGxheW5hbWUiOiJPUCBTZ" \
                  "WxlY3RlZCIsIm5hbWVpZCI6IjQwNGUwNTY3LTE5YTEtNGE2NC1iMmQxLWQzYjBjOTlmMmVkOUBlMzZmMWRiYy1mZGFlLTQyN2UtYj" \
                  "YxYi0wZDk2ZGRmYjgxYTQiLCJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAveW10NmQuc2hhcmVwb2l" \
                  "udC5jb21AZTM2ZjFkYmMtZmRhZS00MjdlLWI2MWItMGQ5NmRkZmI4MWE0IiwiZXhwIjoiMTc1NDk5NTA4NSJ9.CkAKDGVudHJhX2N" \
                  "sYWltcxIwQ09DTjU4UUdFQUFhRmt4TWEwZHlNV3R5ZDJ0MVN6WmFiemxwYkhCbVFVRXFBQT09CjIKCmFjdG9yYXBwaWQSJDAwMDAw" \
                  "MDAzLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMAoKCgRzbmlkEgI2NhILCKa2j4Kms6w-EAUaDjIwLjE5MC4xOTAuMTAwKixhM" \
                  "1l1blg1YkN6MFBCVjM3S2RGblA1QWdyL08wYllnS0FIeU1rU3Rvam1jPTCBAjgBQhChuq4krFAAAHqMwh13MKvaShBoYXNoZWRwcm" \
                  "9vZnRva2VuegExugENc2VsZWN0ZWRzaXRlc8gBAQ._udXSV3Fv81Ws1n5RdRe3aKpVRVZIewLPNiHh8CVjy0"
              end

              let(:upload_url) do
                "https://ymt6d.sharepoint.com/sites/OPTest/_api/v2.0/drives/" \
                  "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK/items/01ANJ53WYPWYGIOMO3WFGK2YENXB7ESIS5" \
                  "/uploadSession?guid=%275fa68ee0-d944-4323-817a-2bf0ece08ae5%27&overwrite=False&rename=True&dc=0&tempa" \
                  "uth=#{token}"
              end

              it_behaves_like "adapter upload_link_query: successful upload link response"
            end

            context "when creating an upload link to a subfolder on a list", vcr: "sharepoint/upload_link_subfolder" do
              let(:folder_id) do
                "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S"
              end
              let(:token) do
                "v1.eyJzaXRlaWQiOiIxMDk5ZTMxNS1kMGM3LTQ3YzctODY0MC1hYTk1MDRiNzBmZmYiLCJhcHBfZGlzcGxheW5hbWUiOiJPUCBTZWx" \
                  "lY3RlZCIsIm5hbWVpZCI6IjQwNGUwNTY3LTE5YTEtNGE2NC1iMmQxLWQzYjBjOTlmMmVkOUBlMzZmMWRiYy1mZGFlLTQyN2UtYjYx" \
                  "Yi0wZDk2ZGRmYjgxYTQiLCJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAveW10NmQuc2hhcmVwb2lud" \
                  "C5jb21AZTM2ZjFkYmMtZmRhZS00MjdlLWI2MWItMGQ5NmRkZmI4MWE0IiwiZXhwIjoiMTc1NTA5MDQ5OSJ9.CkAKDGVudHJhX2NsY" \
                  "WltcxIwQ0piMzdNUUdFQUFhRmpKMU16bElUalJHTFZVeVJWQm9OblpPTmpSUlFVRXFBQT09CjIKCmFjdG9yYXBwaWQSJDAwMDAwMD" \
                  "AzLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMAoKCgRzbmlkEgI2NhILCI7l0_Dq6qw-EAUaDjIwLjE5MC4xOTAuMTAyKixZYld" \
                  "pRDFScDM5SGNsREo0dXQrck5xUjJjelRwbmgya3lSZlhWVnVaZnVBPTCBAjgBQhChuwki92AAAHU0wDr4k3yFShBoYXNoZWRwcm9v" \
                  "ZnRva2VuegExugENc2VsZWN0ZWRzaXRlc8gBAQ.oFWNiNRCsbAVkadc7B2tMRqH4uqjR0oINcqsdEP8DOg"
              end

              let(:upload_url) do
                "https://ymt6d.sharepoint.com/sites/OPTest/_api/v2.0/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY" \
                  "9jo6leJDqrT7muzvmiWjFW/items/01ANJ53W2OGTVJLOZ5R5F2NFJWGJOLV56J/uploadSession?guid=%27ca9855a1-245f-40b" \
                  "6-a2c3-ce8053d3a381%27&overwrite=False&rename=True&dc=0&tempauth=#{token}"
              end

              it_behaves_like "adapter upload_link_query: successful upload link response"
            end

            context "when requesting an upload link for a not existing file", vcr: "sharepoint/upload_link_not_found" do
              let(:input_data) do
                Input::UploadLink.build(
                  folder_id:
                    "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK:04AZJL5PN6Y2GOVW7725BZO354PWSELRRZ",
                  file_name: "DeathStart_blueprints.tiff"
                ).value!
              end
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
