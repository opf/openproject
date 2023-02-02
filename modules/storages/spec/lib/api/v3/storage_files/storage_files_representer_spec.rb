#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe API::V3::StorageFiles::StorageFilesRepresenter do
  let(:user) { build_stubbed(:user) }
  let(:created_at) { DateTime.now }
  let(:last_modified_at) { DateTime.now }

  let(:parent) do
    Storages::StorageFile.new(
      23,
      '/',
      2048,
      'application/x-op-directory',
      created_at,
      last_modified_at,
      'admin',
      'admin',
      '/',
      %i[readable writeable]
    )
  end

  let(:file) do
    Storages::StorageFile.new(
      42,
      'readme.md',
      4096,
      'text/plain',
      created_at,
      last_modified_at,
      'admin',
      'admin',
      '/readme.md',
      %i[readable writeable]
    )
  end

  let(:files) do
    Storages::StorageFiles.new([file], parent)
  end

  let(:representer) { described_class.new(files, current_user: user) }

  subject { representer.to_json }

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { representer._type }
    end

    it_behaves_like 'collection', :files do
      let(:value) { files.files }
      let(:element_decorator) { API::V3::StorageFiles::StorageFileRepresenter }
    end

    it_behaves_like 'property', :parent do
      let(:value) { API::V3::StorageFiles::StorageFileRepresenter.new(files.parent, current_user: user) }
    end
  end
end
