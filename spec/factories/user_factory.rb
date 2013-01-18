FactoryGirl.define do
  factory :user do
    ignore do
        project nil
        projects []
        role nil
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
    first_login false if User.columns.map(&:name).include? 'first_login'

    after(:create) do |user, evaluator|
      evaluator.projects << evaluator.project if evaluator.project
      if !evaluator.projects.empty?
        role = evaluator.role || FactoryGirl.create(:role, :permissions => [:view_issues, :edit_issues])
        evaluator.projects.each do |project|
          if project
            project.add_member! user, role
          end
        end
      end
    end
  end

  factory :admin, :class => User do
    firstname 'Redmine'
    lastname 'Admin'
    login 'admin'
    password 'admin'
    password_confirmation 'admin'
    mail 'admin@example.com'
    admin true
    first_login false if User.columns.map(&:name).include? 'first_login'
  end

  factory :anonymous, :class => AnonymousUser do
    lastname "Anonymous"
    firstname ""
    status User::STATUS_BUILTIN
  end

  factory :deleted_user do
    status User::STATUS_BUILTIN
  end
end
