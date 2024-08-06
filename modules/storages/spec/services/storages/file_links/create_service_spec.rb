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

require "services/base_services/behaves_like_create_service"

RSpec.describe Storages::FileLinks::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :file_link }
  end

  it "creates a journal entry for its container" do
    project_storage = create(:project_storage)

    storage = project_storage.storage
    project = project_storage.project

    # Tap as the changes would otherwise mess with the journal creation i.e. the updated_at timestamp
    work_package = create(:work_package, project:).tap(&:clear_changes_information)
    user = create(:admin)

    service = described_class.new(user:, contract_class: Storages::FileLinks::CreateContract)
    params = { creator: user, container: work_package, origin_id: 200, origin_name: "bob_the_fake_file.png", storage: }

    expect do
      result = service.call(params)
      expect(result).to be_success
    end.to change(Journal, :count).by(1)
  end
end
