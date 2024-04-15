#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Members
  class EditMembershipService
    attr_reader :current_user, :member, :do_save

    def initialize(member, save:, current_user:)
      @current_user = current_user
      @member = member
      @do_save = save
    end

    def call(attributes: {})
      User.execute_as current_user do
        process_attributes! attributes

        unless validate_attributes! attributes
          return make_result(success: false)
        end

        set_attributes(attributes)

        success =
          if do_save
            member.save
          else
            member.validate
          end

        make_result(success:)
      end
    end

    private

    def make_result(success:)
      ServiceResult.new(success:, errors: member.errors, result: member)
    end

    def process_attributes!(attributes)
      # Reject any blank values from unselected values
      if attributes.key? :role_ids
        attributes[:role_ids].reject!(&:blank?)
      end
    end

    ##
    # We need to validate attributes before passing them to user
    # because role_ids are modified instantly and may cause errors if empty
    def validate_attributes!(attributes)
      # We need to check for empty roles here because that _implicitly_
      # deletes the membership and causes failures
      new_roles = attributes[:role_ids]
      new_roles_are_empty = new_roles.nil? || new_roles.empty?

      if new_roles_are_empty && !has_inherited_roles?
        member.errors.add :roles, :role_blank
        return false
      end

      true
    end

    ##
    # Checks whether the member has any inherited role from a group,
    # in which case it is okay to remove all other role_ids.
    def has_inherited_roles?
      member.member_roles.where.not(inherited_from: nil).any?
    end

    def set_attributes(attributes)
      member.attributes = attributes
    end
  end
end
