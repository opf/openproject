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
          RSpec.describe FilePathToIdMapQuery, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW" }
            let(:auth_strategy) { Adapters::Registry["sharepoint.authentication.userless"].call }
            let(:depth) { Float::INFINITY }
            let(:input_data) { Input::FilePathToIdMap.build(folder:, depth:).value! }

            it_behaves_like "storage adapter: query call signature", "file_path_to_id_map"

            context "with parent folder being root", vcr: "sharepoint/file_path_to_id_map_query_root" do
              let(:folder) { "#{base_drive}:/" }

              context "with unset depth (defaults to INFINITY)" do
                let(:expected_ids) do
                  {
                    "/" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W56Y2GOVW7725BZO354PWSELRRZ",
                    "/data" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S",
                    "/empty" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W2MWJ6SKEZPHFGIAAB325KYYMPE",
                    "/My New Folder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WYDT3QB6ENK2RGY73PEXH6FTBUL",
                    "/Test Project Folder Copy Folder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W2LHDLFFGQN4RHJRV6HAK2CFDCT",
                    "/notes.md" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6RWSO6SVC5ZRF3GU7NQK62L3BW",
                    "/simply_oidc.jpg" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WZVLAWJSVFKOFF3HLYZPMPUK6HI",
                    "/data/subfolder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6DBDYX553L4REYNOMUI6XVMTO6",
                    "/data/edge one_drive_health_report_2025-07-22T16_03_25Z.txt" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W26P5RNXU7V2JBKCVQQAGGTO46A",
                    "/My New Folder/Subfolder 123" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WZ4XBSZODGX55BZYCHLDW6T57X7",
                    "/My New Folder/Document.docx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WZBORFHCWETPJE35RDQKPRQPFJ7",
                    "/Test Project Folder Copy Folder/Subfolder 123" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W33OC4BONL5BZH2L4JYCNW6AJG6",
                    "/Test Project Folder Copy Folder/Document.docx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W3UNKXNMYS3HBFKY5MT3JYUMPTF",
                    "/data/subfolder/fw13-easy-effects.json" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W7MUYDYQAA3WVEYDJQNZVSKNPGD",
                    "/My New Folder/Subfolder 123/Subfolder 456" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W7X5XBDGHUB2JBKRVUVCMKXH2KS",
                    "/My New Folder/Subfolder 123/Presentation.pptx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W44YFKD3UIVJBEKK3NW4Y5GBS5P",
                    "/Test Project Folder Copy Folder/Subfolder 123/Subfolder 456" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6QDDNNNJCU4FB2X7TBQVYYSRLT",
                    "/Test Project Folder Copy Folder/Subfolder 123/Presentation.pptx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5X3I2KNO2ISVF2ZQ2TPLZX7CRN"
                  }
                end

                it_behaves_like "adapter file_path_to_id_map_query: successful query"
              end

              context "with a depth of 0" do
                let(:depth) { 0 }
                let(:expected_ids) do
                  {
                    "/" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W56Y2GOVW7725BZO354PWSELRRZ"
                  }
                end

                it_behaves_like "adapter file_path_to_id_map_query: successful query"
              end

              context "with a depth of 1" do
                let(:depth) { 1 }
                let(:expected_ids) do
                  {
                    "/" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W56Y2GOVW7725BZO354PWSELRRZ",
                    "/data" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S",
                    "/empty" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W2MWJ6SKEZPHFGIAAB325KYYMPE",
                    "/My New Folder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WYDT3QB6ENK2RGY73PEXH6FTBUL",
                    "/Test Project Folder Copy Folder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W2LHDLFFGQN4RHJRV6HAK2CFDCT",
                    "/notes.md" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6RWSO6SVC5ZRF3GU7NQK62L3BW",
                    "/simply_oidc.jpg" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53WZVLAWJSVFKOFF3HLYZPMPUK6HI"
                  }
                end

                it_behaves_like "adapter file_path_to_id_map_query: successful query"
              end
            end

            context "with parent folder being not root", vcr: "sharepoint/file_path_to_id_map_query_not_root" do
              context "with folder 1 level after root", vcr: "sharepoint/file_path_to_id_map_query_not_root_1_level" do
                let(:folder) { "#{base_drive}:01ANJ53W2LHDLFFGQN4RHJRV6HAK2CFDCT" }
                let(:expected_ids) do
                  {
                    "/Test Project Folder Copy Folder" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W2LHDLFFGQN4RHJRV6HAK2CFDCT",
                    "/Test Project Folder Copy Folder/Subfolder 123" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W33OC4BONL5BZH2L4JYCNW6AJG6",
                    "/Test Project Folder Copy Folder/Document.docx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W3UNKXNMYS3HBFKY5MT3JYUMPTF",
                    "/Test Project Folder Copy Folder/Subfolder 123/Subfolder 456" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6QDDNNNJCU4FB2X7TBQVYYSRLT",
                    "/Test Project Folder Copy Folder/Subfolder 123/Presentation.pptx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5X3I2KNO2ISVF2ZQ2TPLZX7CRN"
                  }
                end

                it_behaves_like "adapter file_path_to_id_map_query: successful query"
              end

              context "with folder 2 level after root", vcr: "sharepoint/file_path_to_id_map_query_not_root_2_level" do
                let(:folder) { "#{base_drive}:01ANJ53W33OC4BONL5BZH2L4JYCNW6AJG6" }
                let(:expected_ids) do
                  {
                    "/Test Project Folder Copy Folder/Subfolder 123" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W33OC4BONL5BZH2L4JYCNW6AJG6",
                    "/Test Project Folder Copy Folder/Subfolder 123/Subfolder 456" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W6QDDNNNJCU4FB2X7TBQVYYSRLT",
                    "/Test Project Folder Copy Folder/Subfolder 123/Presentation.pptx" => "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW:01ANJ53W5X3I2KNO2ISVF2ZQ2TPLZX7CRN"
                  }
                end

                it_behaves_like "adapter file_path_to_id_map_query: successful query"
              end
            end

            context "with not existent parent folder", vcr: "sharepoint/file_path_to_id_map_query_invalid_parent" do
              let(:folder) { "#{base_drive}:01ANJ53WZVLARJSRFKOFF3HLYZPMPUK6HI " }
              let(:error_source) { Internal::DriveItemQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
