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

RSpec.describe Storages::FileLink do
  let(:creator) { create(:user) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:storage) { create(:nextcloud_storage) }
  let(:attributes) do
    {
      storage:,
      creator:,
      container_id: work_package.id,
      container_type: "WorkPackage",
      origin_id: "123456",
      origin_name: "Origin Name",
      origin_created_by_name: "Peter Pan",
      origin_last_modified_by_name: "Lucy Lectric",
      origin_mime_type: "text/html"
    }
  end

  describe "#create" do
    it "creates an instance" do
      file_link = described_class.create attributes
      expect(file_link).to be_valid
    end

    it "fails when creating an instance with an unsupported container type" do
      file_link = described_class.create(attributes.merge({ container_id: creator.id, container_type: "User" }))
      expect(file_link).not_to be_valid
    end

    it "create instance should fail with empty origin_id" do
      file_link = described_class.create(attributes.merge({ origin_id: "" }))
      expect(file_link).not_to be_valid
    end
  end

  describe "#destroy" do
    let(:file_link_to_destroy) { described_class.create(attributes) }

    before do
      file_link_to_destroy.destroy
    end

    it "destroy instance should leave no file_link" do
      expect(described_class.count).to be 0
    end
  end
end
