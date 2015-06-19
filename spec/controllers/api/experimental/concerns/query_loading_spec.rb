#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'QueryLoading', type: :controller do
  include Api::Experimental::Concerns::QueryLoading
  include QueriesHelper

  describe '#prepare_query' do
    let(:user)    { FactoryGirl.create(:user) }
    let!(:query) do
      FactoryGirl.create :query,
                         user: user
    end
    let(:view_context) { ActionController::Base.new.view_context }

    before do
      allow(User).to receive(:current).and_return(user)
      allow(user).to receive(:allowed_to?).and_return true
      allow(view_context).to receive(:add_filter_from_params)
    end

    context 'accept_empty_query_fields is true' do
      let(:params) { { accept_empty_query_fields: true, query_id: query.id } }
      it 'should call add_filter_from_params' do
        expect(view_context).to receive :add_filter_from_params
        init_query
      end
    end

    context 'accept_empty_query_fields is false or missing' do
      let(:params) { { accept_empty_query_fields: false, query_id: query.id } }
      it 'should not call add_filter_from_params' do
        expect(view_context).not_to receive :add_filter_from_params
        init_query
      end
    end
  end
end
