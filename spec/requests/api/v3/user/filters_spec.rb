#-- encoding: UTF-8

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

require 'spec_helper'

describe 'GET /api/v3/users', type: :request do
  let!(:users) do
    [
      FactoryGirl.create(:admin, login: 'admin', status: Principal::STATUSES[:active]),
      FactoryGirl.create(:user, login: 'h.wurst', status: Principal::STATUSES[:active]),
      FactoryGirl.create(:user, login: 'h.heine', status: Principal::STATUSES[:locked]),
      FactoryGirl.create(:user, login: 'm.mario', status: Principal::STATUSES[:active])
    ]
  end

  before do
    login_as users.first
  end

  def filter_users(name, operator, values)
    filter = {
      name => {
        "operator" => operator,
        "values" => Array(values)
      }
    }
    params = {
      filters: [filter].to_json
    }

    get "/api/v3/users", params: params

    json = JSON.parse response.body

    Array(Hash(json).dig("_embedded", "elements")).map { |e| e["login"] }
  end

  describe 'status filter' do
    it '=' do
      expect(filter_users("status", "=", :active)).to match_array ["admin", "h.wurst", "m.mario"]
    end

    it '!' do
      expect(filter_users("status", "!", :active)).to match_array ["h.heine"]
    end
  end

  describe 'login filter' do
    it '=' do
      expect(filter_users("login", "=", "admin")).to match_array ["admin"]
    end

    it '!' do
      expect(filter_users("login", "!", "admin")).to match_array ["h.wurst", "h.heine", "m.mario"]
    end

    it '~' do
      expect(filter_users("login", "~", "h.")).to match_array ["h.wurst", "h.heine"]
    end

    it '!~' do
      expect(filter_users("login", "!~", "h.")).to match_array ["admin", "m.mario"]
    end
  end
end
