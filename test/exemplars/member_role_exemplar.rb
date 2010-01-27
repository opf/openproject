class MemberRole < ActiveRecord::Base
  generator_for :member, :method => :generate_member
  generator_for :role, :method => :generate_role

  def self.generate_role
    Role.generate!
  end

  def self.generate_member
    Member.generate!
  end
end
