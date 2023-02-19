Rails.application.config.after_initialize do
  ##
  # The default behaviour is to send the user a sign-up mail
  # when they were invited.
  OpenProject::Notifications.subscribe UserInvitation::Events.user_invited do |token|
    Mails::InvitationJob.perform_later(token)
  end

  OpenProject::Notifications.subscribe UserInvitation::Events.user_reinvited do |token|
    Mails::InvitationJob.perform_later(token)
  end
end
