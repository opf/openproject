class QueueNotificationUpdateMail < ActiveRecord::Migration[6.1]
  def up
    User.active.find_each do |user|
      AnnouncementMailer
        .announce(user,
                  subject: I18n.t(:'notifications.update_info_mail.subject'),
                  body: I18n.t(:'notifications.update_info_mail.body'),
                  body_header: I18n.t(:'notifications.update_info_mail.body_header'),
                  body_subheader: I18n.t(:'notifications.update_info_mail.body_subheader'))
        .deliver_later
    end
  end
end
