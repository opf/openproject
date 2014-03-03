class DeleteUserJob
  include Apartment::Delayed::Job::Hooks

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
