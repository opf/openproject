class Member < ActiveRecord::Base
  generator_for :roles, :method => :generate_roles
  generator_for :principal, :method => :generate_user

  def self.generate_roles
    [Role.generate!]
  end

  def self.generate_user
    User.generate_with_protected!
  end
end
