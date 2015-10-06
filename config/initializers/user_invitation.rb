##
# The default behaviour is to send the user a sign-up mail
# when they were invited.
OpenProject::Notifications.subscribe UserInvitation::EVENT_NAME do |token|
  UserMailer.user_signed_up(token).deliver_now
end
