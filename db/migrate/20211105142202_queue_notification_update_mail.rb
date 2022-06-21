class QueueNotificationUpdateMail < ActiveRecord::Migration[6.1]
  def up
    # On a newly created database, we don't want the update mail to be sent.
    # Users are only created upon seeding.
    return unless User.not_builtin.exists?

    ::Announcements::SchedulerJob
      .perform_later subject: :'notifications.update_info_mail.subject',
                     body: :'notifications.update_info_mail.body',
                     body_header: :'notifications.update_info_mail.body_header',
                     body_subheader: :'notifications.update_info_mail.body_subheader'
  end
end
