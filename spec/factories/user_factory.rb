#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :user do
    ignore do
        member_in_project nil
        member_in_projects nil
        member_through_role nil
    end
    firstname 'Bob'
    lastname 'Bobbit'
    sequence(:login) { |n| "bob#{n}" }
    sequence(:mail) {|n| "bob#{n}.bobbit@bob.com" }
    password 'admin'
    password_confirmation 'admin'

    mail_notification(Redmine::VERSION::MAJOR > 0 ? 'all' : true)

    language 'en'
    status User::STATUS_ACTIVE
    admin false
    first_login false if User.table_exists? and User.columns.map(&:name).include? 'first_login'

    after(:build) do |user, evaluator| # this is also done after :create
      (projects = evaluator.member_in_projects || [])
      projects << evaluator.member_in_project if evaluator.member_in_project
      if !projects.empty?
        role = evaluator.member_through_role || FactoryGirl.build(:role, :permissions => [:view_issues, :edit_issues])
        projects.each do |project|
          project.add_member! user, role if project
        end
      end
    end

    factory :admin do
      firstname 'Openproject'
      lastname 'Admin'
      login 'admin'
      password 'admin'
      password_confirmation 'admin'
      mail 'admin@example.com'
      admin true
      first_login false if User.table_exists? and User.columns.map(&:name).include? 'first_login'
    end

    factory :anonymous, :class => AnonymousUser do
      status User::STATUS_BUILTIN
      initialize_with { User.anonymous }
    end

    factory :deleted_user, :class => DeletedUser do
      status User::STATUS_BUILTIN
    end
  end
end
