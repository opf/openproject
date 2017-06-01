##
# The default behaviour is to send the user a sign-up mail
# when they were invited.
OpenProject::Notifications.subscribe UserInvitation::Events.user_invited do |token|
  Delayed::Job.enqueue DeliverInvitationJob.new(token.id)
end

OpenProject::Notifications.subscribe UserInvitation::Events.user_reinvited do |token|
  Delayed::Job.enqueue DeliverInvitationJob.new(token.id)
end
