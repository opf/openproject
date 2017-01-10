#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Users::PaginatedUserCollectionRepresenter do
  let(:self_base_link) { '/api/v3/users' }
  let(:collection_inner_type) { 'User' }
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 2 }
  let(:actual_count) { 3 }

  let(:users) {
    users = FactoryGirl.build_stubbed_list(:user,
                                           actual_count,
                                           created_on: Time.now,
                                           updated_on: Time.now)
    allow(users)
      .to receive(:per_page)
      .with(page_size)
      .and_return(users)

    allow(users)
      .to receive(:page)
      .with(page)
      .and_return(users)

    users
  }
  let(:representer) {
    described_class.new(users,
                        '/api/v3/users',
                        per_page: page_size,
                        page: page,
                        current_user: users.first)
  }

  context 'generation' do
    subject(:collection) { representer.to_json }

    it_behaves_like 'offset-paginated APIv3 collection'
  end
end
