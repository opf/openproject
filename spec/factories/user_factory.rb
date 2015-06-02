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

FactoryGirl.define do
  factory :user do
    transient do
      member_in_project nil
      member_in_projects nil
      member_through_role nil
    end
    firstname 'Bob'
    lastname 'Bobbit'
    sequence(:login) { |n| "bob#{n}" }
    sequence(:mail) { |n| "bob#{n}.bobbit@bob.com" }
    password 'adminADMIN!'
    password_confirmation 'adminADMIN!'
    created_on Time.now
    updated_on Time.now

    mail_notification(Redmine::VERSION::MAJOR > 0 ? 'all' : true)

    language 'en'
    status User::STATUSES[:active]
    admin false
    first_login false if User.table_exists? and User.columns.map(&:name).include? 'first_login'

    callback(:after_build) do |user, evaluator| # this is also done after :create
      (projects = evaluator.member_in_projects || [])
      projects << evaluator.member_in_project if evaluator.member_in_project
      if !projects.empty?
        role = evaluator.member_through_role || FactoryGirl.build(:role, permissions: [:view_work_packages, :edit_work_packages])
        projects.each do |project|
          project.add_member! user, role if project
        end
      end
    end

    factory :admin do
      firstname 'OpenProject'
      sequence(:lastname) { |n| "Admin#{n}" }
      sequence(:login) { |n| "admin#{n}" }
      sequence(:mail) { |n| "admin#{n}@example.com" }
      admin true
      first_login false if User.table_exists? and User.columns.map(&:name).include? 'first_login'
    end

    factory :deleted_user, class: DeletedUser do
      status User::STATUSES[:builtin]
    end

    factory :locked_user do
      firstname 'Locked'
      lastname 'User'
      sequence(:login) { |n| "bob#{n}" }
      sequence(:mail) { |n| "bob#{n}.bobbit@bob.com" }
      password 'adminADMIN!'
      password_confirmation 'adminADMIN!'
      status User::STATUSES[:locked]
    end
  end
  factory :anonymous, class: AnonymousUser do
    status User::STATUSES[:builtin]
    initialize_with { User.anonymous }
  end
end
