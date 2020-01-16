#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

FactoryBot.define do
  factory :user, parent: :principal, class: User do
    firstname { 'Bob' }
    lastname { 'Bobbit' }
    sequence(:login) { |n| "bob#{n}" }
    sequence(:mail) { |n| "bobmail#{n}.bobbit@bob.com" }
    password { 'adminADMIN!' }
    password_confirmation { 'adminADMIN!' }

    mail_notification { OpenProject::VERSION::MAJOR > 0 ? 'all' : true }

    language { 'en' }
    status { User::STATUSES[:active] }
    admin { false }
    first_login { false if User.table_exists? and User.columns.map(&:name).include? 'first_login' }

    factory :admin do
      firstname { 'OpenProject' }
      sequence(:lastname) do |n| "Admin#{n}" end
      sequence(:login) do |n| "admin#{n}" end
      sequence(:mail) do |n| "admin#{n}@example.com" end
      admin { true }
      first_login { false if User.table_exists? and User.columns.map(&:name).include? 'first_login' }
    end

    factory :deleted_user, class: DeletedUser

    factory :locked_user do
      firstname { 'Locked' }
      lastname { 'User' }
      sequence(:login) do |n| "bob#{n}" end
      sequence(:mail) do |n| "bob#{n}.bobbit@bob.com" end
      password { 'adminADMIN!' }
      password_confirmation { 'adminADMIN!' }
      status { User::STATUSES[:locked] }
    end

    factory :invited_user do
      status { User::STATUSES[:invited] }
    end
  end

  factory :anonymous, class: AnonymousUser do
    initialize_with { User.anonymous }
  end

  factory :system, class: SystemUser do
    initialize_with { User.system }
  end
end
