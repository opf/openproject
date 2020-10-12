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

describe MenuItems::QueryMenuItem, type: :model do
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[activity] }
  let(:query) { FactoryBot.create :query, project: project }
  let(:another_query) { FactoryBot.create :query, project: project }

  describe 'it should destroy all items when destroying' do
    before(:each) do
      query_item = FactoryBot.create(:query_menu_item,
                                      query:   query,
                                      name:    'Query Item',
                                      title:   'Query Item')
      another_query_item = FactoryBot.create(:query_menu_item,
                                              query:   another_query,
                                              name:    'Another Query Item',
                                              title:   'Another Query Item')
    end

    it 'the associated query' do
      query.destroy
      expect(MenuItems::QueryMenuItem.where(navigatable_id: query.id)).to be_empty
    end
  end
end
