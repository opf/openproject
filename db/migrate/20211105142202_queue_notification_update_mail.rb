class QueueNotificationUpdateMail < ActiveRecord::Migration[6.1]
  def up
    ::Announcements::SchedulerJob
      .perform_later subject: :'notifications.update_info_mail.subject',
                     body: :'notifications.update_info_mail.body',
                     body_header: :'notifications.update_info_mail.body_header',
                     body_subheader: :'notifications.update_info_mail.body_subheader'
  end
end
