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

module Pages
  module Project
    class Members < Pages::Page
      include Capybara::Select2

      attr_reader :project_identifier

      def initialize(project_identifier)
        @project_identifier = project_identifier
      end

      def path
        "/projects/#{project_identifier}/members"
      end

      def open_new_member!
        click_on 'Add Member'
      end

      ##
      # Adds the given user to this project.
      #
      # @param user_name [String] The full name of the user.
      # @param as [String] The role as which the user should be added.
      def add_user!(user_name, as:)
        click_on 'Add Member'

        select_principal! user_name if user_name
        select_role! as if as

        click_on 'Add'
      end

      def remove_user!(user_name)
        find_user(user_name).find('a[title=Delete]').click
      end

      def has_added_user?(name)
        has_text? "Added #{name} to the project" and
          has_css? 'tr', text: name
      end

      ##
      # Checks if the members page lists the given user.
      #
      # @param name [String] The full name of the user.
      # @param roles [Array] Checks if the user has the given role.
      # @param group_membership [Boolean] True if the member is added through a group.
      #                                   Such members cannot be removed separately which
      #                                   is why there must be only an edit and no delete button.
      def has_user?(name, roles: nil, group_membership: nil)
        has_selector?('tr', text: name) &&
          (roles.nil? || has_roles?(name, roles)) &&
          (group_membership.nil? || group_membership == has_group_membership?(name))
      end

      def find_user(name)
        find('tr', text: name)
      end

      def has_group_membership?(user_name)
        user = find_user(user_name)

        user.has_selector?('a[title=Edit]') &&
          user.has_no_selector?('a[title=Delete]')
      end

      def has_roles?(user_name, roles)
        user = find_user(user_name)

        roles.all? { |role| user.has_text? role }
      end

      def select_principal!(principal_name)
        if !User.current.impaired?
          select2(principal_name, css: '#s2id_member_user_ids')
        else
          find('form .principals').check principal_name
        end
      end

      def select_role!(role_name)
        if !User.current.impaired?
          select2(role_name, css: '#s2id_member_role_ids')
        else
          find('form .roles').check role_name
        end
      end

      def enter_principal_search!(principal_name)
        if !User.current.impaired?
          find('#s2id_member_user_ids')
            .find('.select2-choices .select2-input')
            .set(principal_name)
        else
          fill_in 'principal_search', with: principal_name
        end
      end
    end
  end
end
