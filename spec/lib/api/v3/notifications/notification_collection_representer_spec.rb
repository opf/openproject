#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

describe ::API::V3::Notifications::NotificationCollectionRepresenter do
  let(:self_base_link) { '/api/v3/notifications' }
  let(:user) { build_stubbed :user }
  let(:notifications) do
    build_stubbed_list(:notification,
                                  3).tap do |items|
      allow(items)
        .to receive(:per_page)
              .with(page_size)
              .and_return(items)

      allow(items)
        .to receive(:page)
              .with(page)
              .and_return(items)

      allow(items)
        .to receive(:count)
              .and_return(total)
    end
  end
  let(:current_user) { build_stubbed(:user) }
  let(:representer) do
    described_class.new(notifications,
                        self_link: self_base_link,
                        per_page: page_size,
                        page: page,
                        groups: groups,
                        current_user: current_user)
  end
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 2 }
  let(:actual_count) { 3 }
  let(:collection_inner_type) { 'Notification' }
  let(:groups) { nil }

  include API::V3::Utilities::PathHelper

  before do
    allow(API::V3::Notifications::NotificationEagerLoadingWrapper)
      .to receive(:wrap)
            .with(notifications)
            .and_return(notifications)
  end

  describe 'generation' do
    subject(:collection) { representer.to_json }

    it_behaves_like 'offset-paginated APIv3 collection', 3, 'notifications', 'Notification'

    context 'when passing groups' do
      let(:groups) do
        [
          { value: 'mentioned', count: 34 },
          { value: 'involved', count: 5 }
        ]
      end

      it 'renders the groups object as json' do
        expect(subject).to be_json_eql(groups.to_json).at_path('groups')
      end
    end
  end
end
