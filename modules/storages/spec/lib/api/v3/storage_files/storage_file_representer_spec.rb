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

RSpec.describe API::V3::StorageFiles::StorageFileRepresenter do
  let(:user) { build_stubbed(:user) }
  let(:created_at) { DateTime.now }
  let(:last_modified_at) { DateTime.now }
  let(:storage) { build_stubbed(:nextcloud_storage) }
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
      location: "/readme.md",
      permissions: %i[readable writeable]
    )
  end
  let(:representer) { described_class.new(file, storage, current_user: user) }

  subject { representer.to_json }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { representer._type }
    end

    it_behaves_like "property", :id do
      let(:value) { file.id }
    end

    it_behaves_like "property", :name do
      let(:value) { file.name }
    end

    it_behaves_like "property", :size do
      let(:value) { file.size }
    end

    it_behaves_like "property", :mimeType do
      let(:value) { file.mime_type }
    end

    it_behaves_like "datetime property", :createdAt do
      let(:value) { file.created_at }
    end

    it_behaves_like "datetime property", :lastModifiedAt do
      let(:value) { file.last_modified_at }
    end

    it_behaves_like "property", :createdByName do
      let(:value) { file.created_by_name }
    end

    it_behaves_like "property", :lastModifiedByName do
      let(:value) { file.last_modified_by_name }
    end

    it_behaves_like "property", :location do
      let(:value) { file.location }
    end

    it_behaves_like "property", :permissions do
      let(:value) { file.permissions }
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { "/api/v3/storages/#{storage.id}/files/#{file.id}" }
        let(:title) { file.name }
      end
    end
  end
end
