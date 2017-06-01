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

require 'digest'

FactoryGirl.define do
  factory :role do
    permissions []
    sequence(:name) do |n| "role_#{n}" end
    assignable true

    factory :non_member do
      name 'Non member'
      builtin Role::BUILTIN_NON_MEMBER
      assignable false
      initialize_with { Role.find_or_create_by(name: name) }
    end

    factory :anonymous_role do
      name 'Anonymous'
      builtin Role::BUILTIN_ANONYMOUS
      assignable false
      initialize_with { Role.find_or_create_by(name: name) }
    end

    factory :existing_role do
      name { 'Role ' + Digest::MD5.hexdigest(permissions.map(&:to_s).join('/'))[0..4] }
      assignable true
      permissions []

      initialize_with do
        role =
          if Role.where(name: name).exists?
            Role.find_by(name: name)
          else
            Role.create name: name, assignable: assignable
          end

        role.add_permission!(*permissions.reject { |p| role.permissions.include?(p) })

        role
      end
    end
  end
end
