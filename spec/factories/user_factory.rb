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

FactoryBot.define do
  factory :user, parent: :principal, class: "User" do
    firstname { "Bob" }
    lastname { "Bobbit" }
    sequence(:login) { |n| "bob#{n}" }
    sequence(:mail) { |n| "bobmail#{n}.bobbit@bob.com" }
    password { "adminADMIN!" }
    password_confirmation { "adminADMIN!" }

    transient do
      preferences { {} }
    end

    language { "en" }
    status { User.statuses[:active] }
    admin { false }
    first_login { false if User.table_exists? and User.columns.map(&:name).include? "first_login" }

    callback(:after_build) do |user, evaluator|
      evaluator.preferences&.each do |key, val|
        user.pref[key] = val
      end
    end

    callback(:after_create) do |user, factory|
      user.pref.save if factory.preferences.present?

      if user.notification_settings.empty?
        user.notification_settings = [
          create(:notification_setting, user:)
        ]
      end
    end

    callback(:after_stub) do |user, evaluator|
      if evaluator.preferences.present?
        # The assign_attributes workaround is required, because assigning user.preference will trigger
        # creating a new database record, which raises an error in the build_stubbed context
        user.pref.assign_attributes(
          build_stubbed(:user_preference, user:, settings: evaluator.preferences).attributes
        )
      end
    end

    factory :admin do
      firstname { "OpenProject" }
      sequence(:lastname) { |n| "Admin#{n}" }
      sequence(:login) { |n| "admin#{n}" }
      sequence(:mail) { |n| "admin#{n}@example.com" }
      admin { true }
      first_login { false if User.table_exists? and User.columns.map(&:name).include? "first_login" }
    end

    factory :deleted_user, class: "DeletedUser"

    factory :locked_user do
      firstname { "Locked" }
      lastname { "User" }
      sequence(:login) { |n| "locked#{n}" }
      sequence(:mail) { |n| "locked#{n}@bob.com" }
      password { "adminADMIN!" }
      password_confirmation { "adminADMIN!" }
      status { User.statuses[:locked] }
    end

    factory :invited_user do
      status { User.statuses[:invited] }
    end
  end

  factory :anonymous, class: "AnonymousUser" do
    initialize_with { User.anonymous }
  end

  factory :system, class: "SystemUser" do
    initialize_with { User.system }
  end
end
