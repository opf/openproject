require 'multitenancy/delayed_job/hooks'

class DeliverWorkPackageUpdatedJob
  include Multitenancy::Delayed::Job::Hooks

  def initialize(user_id, journal_id, current_user_id)
    super
    @user_id         = user_id
    @journal_id      = journal_id
    @current_user_id = current_user_id
  end

  def perform
    notification_mail.deliver
  end

private

  def notification_mail
    @notification_mail ||= UserMailer.work_package_updated(user, journal, current_user)
  end

  def user
    @user ||= Principal.find(@user_id)
  end

  def journal
    @journal ||= Journal.find(@journal_id)
  end

  def current_user
    @current_user ||= Principal.find(@current_user_id)
  end
end
