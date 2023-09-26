# frozen_string_literal: true

class SharingMailer < ApplicationMailer
  helper :mail_notification

  def shared_work_package(sharer, membership)
    @sharer = sharer
    @work_package = membership.entity

    role = membership.roles.first
    @role_rights = derive_role_rights(role)
    @allowed_work_package_actions = derive_allowed_work_package_actions(role)

    recipient = membership.principal

    with_locale_for(recipient) do
      mail to: recipient.mail,
           subject: I18n.t('mail.sharing.work_packages.subject',
                           id: @work_package.id)
    end
  end

  private

  def derive_role_rights(role)
    case role.builtin
    when Role::BUILTIN_WORK_PACKAGE_EDITOR
      I18n.t('work_package.sharing.permissions.edit')
    when Role::BUILTIN_WORK_PACKAGE_COMMENTER
      I18n.t('work_package.sharing.permissions.comment')
    when Role::BUILTIN_WORK_PACKAGE_VIEWER
      I18n.t('work_package.sharing.permissions.view')
    end
  end

  def derive_allowed_work_package_actions(role)
    allowed_actions = case role.builtin
                      when Role::BUILTIN_WORK_PACKAGE_EDITOR
                        [I18n.t('work_package.sharing.permissions.view'),
                         I18n.t('work_package.sharing.permissions.comment'),
                         I18n.t('work_package.sharing.permissions.edit')]
                      when Role::BUILTIN_WORK_PACKAGE_COMMENTER
                        [I18n.t('work_package.sharing.permissions.view'),
                         I18n.t('work_package.sharing.permissions.comment')]
                      when Role::BUILTIN_WORK_PACKAGE_VIEWER
                        [I18n.t('work_package.sharing.permissions.view')]
                      end

    allowed_actions = allowed_actions.map do |action|
      "<span style=\"font-weight:bold;\">#{action.downcase}</span>"
    end

    allowed_actions.to_sentence
  end
end
