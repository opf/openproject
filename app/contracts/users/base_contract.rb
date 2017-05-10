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

require 'model_contract'

module Users
  class BaseContract < ::ModelContract
    attribute :type
    attribute :login
    attribute :firstname
    attribute :lastname
    attribute :name
    attribute :mail
    attribute :admin

    attribute :auth_source_id
    attribute :identity_url
    attribute :password

    def self.model
      User
    end

    def initialize(user, current_user)
      super(user)

      @current_user = current_user
    end

    def validate
      existing_auth_source

      super
    end

    private

    attr_reader :current_user

    def existing_auth_source
      if auth_source_id && AuthSource.find_by_unique(auth_source_id).nil?
        errors.add :auth_source, :error_not_found
      end
    end
  end
end
