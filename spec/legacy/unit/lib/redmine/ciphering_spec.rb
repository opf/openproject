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
#++
require 'legacy_spec_helper'

describe Redmine::Ciphering do
  it 'should password should be encrypted' do
    OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
      r = Repository::Subversion.generate!(password: 'foo')
      assert_equal 'foo', r.password
      assert r.read_attribute(:password).match(/\Aaes-256-cbc:.+\Z/)
    end
  end

  it 'should password should be clear with blank key' do
    OpenProject::Configuration.with 'database_cipher_key' => '' do
      r = Repository::Subversion.generate!(password: 'foo')
      assert_equal 'foo', r.password
      assert_equal 'foo', r.read_attribute(:password)
    end
  end

  it 'should password should be clear with nil key' do
    OpenProject::Configuration.with 'database_cipher_key' => nil do
      r = Repository::Subversion.generate!(password: 'foo')
      assert_equal 'foo', r.password
      assert_equal 'foo', r.read_attribute(:password)
    end
  end

  it 'should unciphered password should be readable' do
    OpenProject::Configuration.with 'database_cipher_key' => nil do
      r = Repository::Subversion.generate!(password: 'clear')
    end

    OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
      r = Repository.first(order: 'id DESC')
      assert_equal 'clear', r.password
    end
  end

  it 'should encrypt all' do
    Repository.delete_all
    OpenProject::Configuration.with 'database_cipher_key' => nil do
      Repository::Subversion.generate!(password: 'foo')
      Repository::Subversion.generate!(password: 'bar')
    end

    OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
      assert Repository.encrypt_all(:password)
      r = Repository.first(order: 'id DESC')
      assert_equal 'bar', r.password
      assert r.read_attribute(:password).match(/\Aaes-256-cbc:.+\Z/)
    end
  end

  it 'should decrypt all' do
    Repository.delete_all
    OpenProject::Configuration.with 'database_cipher_key' => 'secret' do
      Repository::Subversion.generate!(password: 'foo')
      Repository::Subversion.generate!(password: 'bar')

      assert Repository.decrypt_all(:password)
      r = Repository.first(order: 'id DESC')
      assert_equal 'bar', r.password
      assert_equal 'bar', r.read_attribute(:password)
    end
  end
end
