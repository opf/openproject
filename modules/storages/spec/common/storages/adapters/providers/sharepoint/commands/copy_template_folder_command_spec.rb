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
        module Commands
          RSpec.describe CopyTemplateFolderCommand, :disable_ssrf_filter, :webmock do
            shared_let(:storage) { create(:sharepoint_storage, :sandbox) }
            shared_let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW" }

            let(:input_data) { Input::CopyTemplateFolder.build(source:, destination:).value! }
            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }

            it "is registered under commands.sharepoint.copy_template_folder" do
              expect(Registry.resolve("sharepoint.commands.copy_template_folder")).to eq(described_class)
            end

            it "responds to .call" do
              expect(described_class).to respond_to(:call)
            end

            describe "#call" do
              let(:source) { "#{base_drive}:01ANJ53W2LHDLFFGQN4RHJRV6HAK2CFDCT" }
              let(:destination) { "My New Folder" }

              it "copies origin folder and all underlying files and folders to the destination_path",
                 vcr: "sharepoint/copy_template_folder_copy_successful" do
                command_result = described_class.call(auth_strategy:, storage:, input_data:)

                expect(command_result).to be_success
                data = command_result.value!

                expect(data).to be_requires_polling
                expect(data.polling_url).to match %r</drives/#{base_drive}/items/.+\?.+$>
              end

              describe "error handling" do
                context "when the source_path does not exist" do
                  let(:source) { "#{base_drive}:TheCakeIsALie" }
                  let(:destination) { "Not Happening" }

                  it "fails", vcr: "sharepoint/copy_template_source_not_found" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result).to be_failure
                    expect(result.failure.code).to eq(:not_found)
                  end
                end

                context "when it would overwrite an already existing folder" do
                  let(:destination) { "My New Folder" }

                  it "fails", vcr: "sharepoint/copy_template_folder_no_overwrite" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result).to be_failure
                    expect(result.failure.code).to eq(:error)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
