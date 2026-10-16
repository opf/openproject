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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :notification_setting do
    transient do
      all { nil } # set to true to turn all settings to true
    end

    assignee { true }
    responsible { true }
    mentioned { true }
    watched { true }
    work_package_commented { false }
    work_package_created { false }
    work_package_processed { false }
    work_package_prioritized { false }
    work_package_scheduled { false }
    news_added { false }
    news_commented { false }
    document_added { false }
    forum_messages { false }
    wiki_page_added { false }
    wiki_page_updated { false }
    membership_added { false }
    membership_updated { false }
    project { nil } # Default settings
    user

    callback(:after_build, :after_stub) do |notification_setting, evaluator|
      if evaluator.all == true
        all_boolean_settings = NotificationSetting.all_settings - NotificationSetting.date_alert_settings
        all_true = all_boolean_settings.index_with(true)
        notification_setting.assign_attributes(all_true)
      end
    end
  end
end
