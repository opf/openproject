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

module MemberHelper
  module_function

  def find_role_ids(builtin_value)
    # Role has a left join on permissions included leading to multiple ids being returned which
    # is why we unscope.
    WorkPackageRole.unscoped.where(builtin: builtin_value).pluck(:id)
  end

  def find_or_create_users(send_notification: true)
    @send_notification = send_notification

    user_ids.each do |id|
      yield permitted_params.member.merge(user_id: id, project: @project)
    end
  end

  def user_ids
    user_ids = user_ids_for_new_members(params[:member])

    group_ids = Group.where(id: user_ids).pluck(:id)

    user_ids.sort_by! { |id| group_ids.include?(id) ? 1 : -1 }

    user_ids
  end

  def user_ids_for_new_members(member_params)
    invite_new_users possibly_separated_ids_for_entity(member_params, :user), send_notification: @send_notification
  end

  def invite_new_users(user_ids, send_notification: true)
    user_ids.filter_map do |id|
      if id.to_i == 0 && id.present? # we've got an email - invite that user
        # Only users with the create_user permission can add users.
        if current_user.allowed_globally?(:create_user) && enterprise_allow_new_users?
          # The invitation can pretty much only fail due to the user already
          # having been invited. So look them up if it does.
          user = UserInvitation.invite_new_user(email: id, send_notification:) ||
            User.find_by_mail(id)

          user&.id
        end
      else
        id
      end
    end
  end

  def enterprise_allow_new_users?
    !OpenProject::Enterprise.user_limit_reached? || !OpenProject::Enterprise.fail_fast?
  end

  def each_comma_separated(array, &)
    array.map(&).flatten
  end

  def transform_array_of_comma_separated_ids(array)
    return Array(array) unless array.is_a?(Array)
    return array if array.blank?

    each_comma_separated(array) do |elem|
      elem.to_s.split(',')
    end
  end

  def possibly_separated_ids_for_entity(array, entity = :user)
    if !array[:"#{entity}_ids"].nil?
      transform_array_of_comma_separated_ids(array[:"#{entity}_ids"])
    elsif !array[:"#{entity}_id"].nil?
      transform_array_of_comma_separated_ids(array[:"#{entity}_id"])
    else
      []
    end
  end
end
