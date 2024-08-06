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

RSpec.describe API::V3::StorageFiles::StorageFilesRepresenter do
  let(:user) { build_stubbed(:user) }
  let(:storage) { build_stubbed(:nextcloud_storage) }
  let(:created_at) { DateTime.now }
  let(:last_modified_at) { DateTime.now }

  let(:parent) do
    Storages::StorageFile.new(
      id: 23,
      name: "Documents",
      size: 2048,
      mime_type: "application/x-op-directory",
      created_at:,
      last_modified_at:,
      created_by_name: "admin",
      last_modified_by_name: "admin",
      location: "/Documents",
      permissions: %i[readable writeable]
    )
  end

  let(:file) do
    Storages::StorageFile.new(
      id: 42,
      name: "readme.md",
      size: 4096,
      mime_type: "text/plain",
      created_at:,
      last_modified_at:,
      created_by_name: "admin",
      last_modified_by_name: "admin",
      location: "/Documents/readme.md",
      permissions: %i[readable writeable]
    )
  end

  let(:ancestor) do
    Storages::StorageFile.new(
      id: 47,
      name: "/",
      size: 4096,
      mime_type: "application/x-op-directory",
      created_at:,
      last_modified_at:,
      created_by_name: "admin",
      last_modified_by_name: "admin",
      location: "/",
      permissions: %i[readable writeable]
    )
  end

  let(:files) do
    Storages::StorageFiles.new([file], parent, [ancestor])
  end

  let(:representer) { described_class.new(files, storage, current_user: user) }

  subject { representer.to_json }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { representer._type }
    end

    it_behaves_like "collection", :files do
      let(:value) { files.files }
      let(:element_decorator) do
        ->(value) { API::V3::StorageFiles::StorageFileRepresenter.new(value, storage, current_user: user) }
      end
    end

    it_behaves_like "collection", :ancestors do
      let(:value) { files.ancestors }
      let(:element_decorator) do
        ->(value) { API::V3::StorageFiles::StorageFileRepresenter.new(value, storage, current_user: user) }
      end
    end

    it_behaves_like "property", :parent do
      let(:value) { API::V3::StorageFiles::StorageFileRepresenter.new(files.parent, storage, current_user: user) }
    end
  end
end
