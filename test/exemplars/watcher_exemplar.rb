class Watcher < ActiveRecord::Base
  generator_for :user, :method => :generate_user

  def self.generate_user
    User.generate_with_protected!
  end
end
