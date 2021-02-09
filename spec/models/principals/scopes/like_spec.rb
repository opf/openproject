#-- encoding: UTF-8

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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Principals::Scopes::Like, type: :model do
  describe '.like' do
    let!(:login) do
      FactoryBot.create(:principal, login: 'login')
    end
    let!(:login2) do
      FactoryBot.create(:principal, login: 'login2')
    end
    let!(:firstname) do
      FactoryBot.create(:principal, firstname: 'firstname')
    end
    let!(:firstname2) do
      FactoryBot.create(:principal, firstname: 'firstname2')
    end
    let!(:lastname) do
      FactoryBot.create(:principal, lastname: 'lastname')
    end
    let!(:lastname2) do
      FactoryBot.create(:principal, lastname: 'lastname2')
    end
    let!(:mail) do
      FactoryBot.create(:principal, mail: 'mail@example.com')
    end
    let!(:mail2) do
      FactoryBot.create(:principal, mail: 'mail2@example.com')
    end

    it 'finds by login' do
      expect(Principal.like('login'))
        .to match_array [login, login2]
    end

    it 'finds by firstname' do
      expect(Principal.like('firstname'))
        .to match_array [firstname, firstname2]
    end

    it 'finds by lastname' do
      expect(Principal.like('lastname'))
        .to match_array [lastname, lastname2]
    end

    it 'finds by mail' do
      expect(Principal.like('mail'))
        .to match_array [mail, mail2]
    end
  end
end
