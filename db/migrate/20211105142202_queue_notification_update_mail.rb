class QueueNotificationUpdateMail < ActiveRecord::Migration[6.1]
  def up
    ::Announcements::SchedulerJob
      .perform_later subject: I18n.t(:'notifications.update_info_mail.subject'),
                     body: I18n.t(:'notifications.update_info_mail.body'),
                     body_header: I18n.t(:'notifications.update_info_mail.body_header'),
                     body_subheader: I18n.t(:'notifications.update_info_mail.body_subheader')
  end
end
