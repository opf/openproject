# frozen_string_literal: true

class SharingMailer < ApplicationMailer
  def shared_work_package(_sharer, membership)
    work_package = membership.entity
    recipient = membership.principal

    with_locale_for(recipient) do
      mail to: recipient.mail,
           subject: I18n.t('mail.sharing.work_packages.subject',
                           id: work_package.id)
    end
  end
end
