#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Memberships::MembershipCollectionRepresenter do
  let(:self_base_link) { '/api/v3/members' }
  let(:members) do
    FactoryBot.build_stubbed_list(:member, 3).tap do |members|
      allow(members)
        .to receive(:per_page)
        .with(page_size)
        .and_return(members)

      allow(members)
        .to receive(:page)
        .with(page)
        .and_return(members)
    end
  end
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.new(members,
                        self_base_link,
                        per_page: page_size,
                        page: page,
                        current_user: current_user)
  end
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 2 }
  let(:actual_count) { 3 }
  let(:collection_inner_type) { 'Membership' }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject(:collection) { representer.to_json }

    it_behaves_like 'offset-paginated APIv3 collection', 3, 'members', 'Membership'
  end
end
