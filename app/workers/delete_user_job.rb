require 'subscribem/delayed_job/hooks'

class DeleteUserJob
  include Subscribem::Delayed::Job::Hooks

  def initialize(user_id)
    @user_id  = user_id
    @database = Apartment::Database.current_database
  end

  def perform
    user.destroy
  end

private

  def user
    @user ||= User.find(@user_id)
  end
end
