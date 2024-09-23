# frozen_string_literal: true

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

class Activities::ItemSubtitleComponent < ViewComponent::Base
  def initialize(user:, datetime:, is_creation:, is_deletion:, is_work_package:, journable_type:)
    super()
    @user = user
    @datetime = datetime
    @is_creation = is_creation
    @is_deletion = is_deletion
    @is_work_package = is_work_package
    @journable_type = journable_type
  end

  def user_html
    return unless @user

    [
      helpers.avatar(@user, size: "mini"),
      helpers.content_tag("span", helpers.link_to_user(@user), class: %w[spot-caption spot-caption_bold])
    ].join(" ")
  end

  def datetime_html
    helpers.format_time(@datetime)
  end

  def time_entry?
    @journable_type == "TimeEntry"
  end

  def i18n_key
    i18n_key = +"activity.item."
    i18n_key << (@is_deletion ? deletion_selector : creation_selector)
    i18n_key << "by_" if @user
    i18n_key << "on"
    i18n_key << "_time_entry" if time_entry?
    i18n_key
  end

  def deletion_selector
    @is_work_package ? "removed_" : "deleted_"
  end

  def creation_selector
    if @is_creation
      @is_work_package ? "added_" : "created_"
    else
      "updated_"
    end
  end
end
