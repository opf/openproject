class DeliverWorkPackageUpdatedJob
  include Apartment::Delayed::Job::Hooks

  def initialize(user_id, journal_id, current_user_id)
    @user_id         = user_id
    @journal_id      = journal_id
    @current_user_id = current_user_id
    @database        = Apartment::Database.current_database
  end

  def perform
    notification_mail.deliver
  end

private

  def notification_mail
    @notification_mail ||= UserMailer.issue_updated(user, journal, current_user)
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
