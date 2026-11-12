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

RSpec.shared_examples_for "adapter upload_file_command: successful file upload" do
  it "uploads the file" do
    result = described_class.call(storage:, auth_strategy:, input_data:)

    expect(result).to be_success

    response = result.value!
    expect(response).to be_a(Storages::Adapters::Results::StorageFile)
    expect(response.name).to eq(file_name)
    # Location format varies by provider (path-based for Nextcloud, path from webUrl for SharePoint)
    # Nextcloud: location matches "#{parent_location}#{file_name}"
    # SharePoint: location is a path extracted from webUrl, so we just verify it's present
    if parent_location.is_a?(String) && parent_location.start_with?("/")
      expect(response.location).to eq("#{parent_location}#{file_name}")
    else
      expect(response.location).to be_present
    end
    expect(response.mime_type).to eq("text/plain")
  end
end
