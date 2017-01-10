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

describe Api::V2::StatusesController, type: :controller do
  let(:valid_user) { FactoryGirl.create(:user) }
  let(:status)     { FactoryGirl.create(:status) }

  before do
    allow(User).to receive(:current).and_return valid_user
  end

  describe 'looking up a singular status' do
    let(:closed) { FactoryGirl.create(:status, name: 'Closed') }

    it 'that does not exist should raise an error' do
      get 'show', params: { id: '0' }, format: 'json'
      expect(response.response_code).to eq(404)
    end
    it 'that exists should return the proper status' do
      get 'show', params: { id: closed.id }, format: 'json'
      expect(assigns(:status)).to eql closed
    end
  end

  describe 'looking up statuses' do
    let!(:open) { FactoryGirl.create(:status, name: 'Open') }
    let!(:in_progress) { FactoryGirl.create(:status, name: 'In Progress') }
    let!(:closed) { FactoryGirl.create(:status, name: 'Closed') }

    it 'should return all statuses' do
      get 'index', format: 'json'

      expect(assigns(:statuses)).to include open, in_progress, closed
    end
  end
end
