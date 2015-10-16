##
# The default behaviour is to send the user a sign-up mail
# when they were invited.
OpenProject::Notifications.subscribe UserInvitation::EVENT_NAME do |token|
  Delayed::Job.enqueue DeliverInvitationJob.new(token.id)
end
