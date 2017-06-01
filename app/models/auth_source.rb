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

class AuthSource < ActiveRecord::Base
  include Redmine::Ciphering

  has_many :users

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, maximum: 60

  def self.unique_attribute
    :name
  end
  prepend ::Mixins::UniqueFinder

  def authenticate(_login, _password)
  end

  # implemented by a subclass, should raise when no connection is possible and not raise on success
  def test_connection
    raise I18n.t('auth_source.using_abstract_auth_source')
  end

  def auth_method_name
    'Abstract'
  end

  def account_password
    read_ciphered_attribute(:account_password)
  end

  def account_password=(arg)
    write_ciphered_attribute(:account_password, arg)
  end

  def allow_password_changes?
    self.class.allow_password_changes?
  end

  # Does this auth source backend allow password changes?
  def self.allow_password_changes?
    false
  end

  # Try to authenticate a user not yet registered against available sources
  def self.authenticate(login, password)
    AuthSource.where(['onthefly_register=?', true]).each do |source|
      begin
        Rails.logger.debug { "Authenticating '#{login}' against '#{source.name}'" }
        attrs = source.authenticate(login, password)
      rescue => e
        Rails.logger.error "Error during authentication: #{e.message}"
        attrs = nil
      end
      return attrs if attrs
    end
    nil
  end
end
