# frozen_string_literal: true

class SharingMailer < ApplicationMailer
  helper :mail_notification

  def shared_work_package(sharer, membership, group = nil)
    @sharer = sharer
    @shared_with_user = membership.principal
    @group = group
    @work_package = membership.entity

    role = membership.roles.first
    @role_rights = derive_role_rights(role)
    @allowed_work_package_actions = derive_allowed_work_package_actions(role)

    set_open_project_headers(@work_package)
    message_id(membership, sharer)

    with_locale_for(@shared_with_user) do
      mail to: @shared_with_user.mail,
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

    allowed_actions.map(&:downcase)
  end

  def set_open_project_headers(work_package)
    open_project_headers 'Project' => work_package.project.identifier,
                         'WorkPackage-Id' => work_package.id,
                         'Type' => 'WorkPackage'
  end
end
