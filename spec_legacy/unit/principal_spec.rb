#-- encoding: UTF-8
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
require 'legacy_spec_helper'

describe Principal, type: :model do
  context '#like' do
    before do
      FactoryGirl.create(:principal, login: 'login')
      FactoryGirl.create(:principal, login: 'login2')

      FactoryGirl.create(:principal, firstname: 'firstname')
      FactoryGirl.create(:principal, firstname: 'firstname2')

      FactoryGirl.create(:principal, lastname: 'lastname')
      FactoryGirl.create(:principal, lastname: 'lastname2')

      FactoryGirl.create(:principal, mail: 'mail@example.com')
      FactoryGirl.create(:principal, mail: 'mail2@example.com')
    end

    it 'should search login' do
      results = Principal.like('login')

      assert_equal 2, results.count
      assert results.all? { |u| u.login.match(/login/) }
    end

    it 'should search firstname' do
      results = Principal.like('firstname')

      assert_equal 2, results.count
      assert results.all? { |u| u.firstname.match(/firstname/) }
    end

    it 'should search lastname' do
      results = Principal.like('lastname')

      assert_equal 2, results.count
      assert results.all? { |u| u.lastname.match(/lastname/) }
    end

    it 'should search mail' do
      results = Principal.like('mail')

      assert_equal 2, results.count
      assert results.all? { |u| u.mail.match(/mail/) }
    end
  end
end
