require 'multitenancy/delayed_job/hooks'

class DeleteUserJob
  include Multitenancy::Delayed::Job::Hooks

  def initialize(user_id)
    super
    @user_id = user_id
  end

  def perform
    user.destroy
  end

private

  def user
    @user ||= User.find(@user_id)
  end
end
