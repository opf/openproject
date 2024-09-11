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

require "services/base_services/behaves_like_delete_service"

RSpec.describe Storages::FileLinks::DeleteService, type: :model do
  it_behaves_like "BaseServices delete service" do
    let(:factory) { :file_link }
  end

  it "creates a journal entry for its container", with_settings: { journal_aggregation_time_minutes: 0 } do
    project_storage = create(:project_storage)
    # Tap as the changes would otherwise mess with the journal creation i.e. the updated_at timestamp
    work_package = create(:work_package, project: project_storage.project).tap(&:clear_changes_information)

    file_link = create(:file_link, container: work_package, storage: project_storage.storage)

    service = described_class.new(model: file_link, user: create(:admin), contract_class: Storages::FileLinks::DeleteContract)
    params = { id: file_link.id }

    # We need a previous entry that added the file link to record the removal
    work_package.save_journals

    expect do
      result = service.call(params)
      expect(result).to be_success
    end.to change(Journal, :count).by(1)
  end
end
