#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Queries::Filters::Shared::AnyUserNameAttributeFilter
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def key
      :any_name_attribute
    end

    def available_operators
      [Queries::Operators::Contains,
       Queries::Operators::Everywhere,
       Queries::Operators::NotContains]
    end

    def email_field_allowed?
      User.current.allowed_globally?(:view_user_email)
    end

    private

    def sql_concat_name
      fields = <<~SQL.squish
        users.firstname, ' ', users.lastname,
        ' ',
        users.lastname, ' ', users.firstname,
        ' ',
        users.login
      SQL

      fields << ", ' ',users.mail" if email_field_allowed?

      <<~SQL.squish
        LOWER(CONCAT(#{fields}))
      SQL
    end
  end

  module ClassMethods
    def key
      :any_name_attribute
    end
  end
end
