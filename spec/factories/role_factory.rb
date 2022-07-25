#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'digest'

FactoryBot.define do
  factory :role do
    permissions { [] }
    sequence(:name) { |n| "role_#{n}" }

    factory :non_member do
      name { 'Non member' }
      builtin { Role::BUILTIN_NON_MEMBER }
      initialize_with { Role.where(name:).first_or_initialize }
    end

    factory :anonymous_role do
      name { 'Anonymous' }
      builtin { Role::BUILTIN_ANONYMOUS }
      initialize_with { Role.where(name:).first_or_initialize }
    end

    factory :existing_role do
      name { "Role #{Digest::MD5.hexdigest(permissions.map(&:to_s).join('/'))[0..4]}" }
      permissions { [] }

      initialize_with do
        role =
          if Role.where(name:).exists?
            Role.find_by(name:)
          else
            Role.create name: name
          end

        role.add_permission!(*permissions.reject { |p| role.permissions.include?(p) })

        role
      end
    end
  end
end
