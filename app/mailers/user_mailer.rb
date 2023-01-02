#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class UserMailer < ApplicationMailer
  include MessagesHelper

  helper_method :message_url

  def test_mail(user)
    @welcome_url = url_for(controller: '/homescreen')

    open_project_headers 'Type' => 'Test'

    send_mail(user,
              'OpenProject Test')
  end

  def backup_ready(user)
    User.execute_as user do
      @download_url = admin_backups_url

      send_mail(user,
                I18n.t("mail_subject_backup_ready"))
    end
  end

  def backup_token_reset(recipient, user:, waiting_period: OpenProject::Configuration.backup_initial_waiting_period)
    @admin_notification = recipient != user # notification for other admins rather than oneself
    @user_login = user.login
    @waiting_period = waiting_period

    User.execute_as recipient do
      send_mail(recipient,
                I18n.t("mail_subject_backup_token_reset"))
    end
  end

  def password_lost(token)
    return unless token.user # token's can have no user

    @token = token
    @reset_password_url = url_for(controller: '/account',
                                  action: :lost_password,
                                  token: @token.value)

    open_project_headers 'Type' => 'Account'

    send_mail(token.user,
              t(:mail_subject_lost_password, value: Setting.app_title))
  end

  def news_added(user, news)
    @news = news

    open_project_headers 'Type'    => 'News'
    open_project_headers 'Project' => @news.project.identifier if @news.project

    message_id @news, user
    references @news

    subject = "#{News.model_name.human}: #{@news.title}"
    subject = "[#{@news.project.name}] #{subject}" if @news.project

    send_mail(user, subject)
  end

  def user_signed_up(token)
    return unless token.user

    @user = token.user
    @token = token
    @activation_url = url_for(controller: '/account',
                              action: :activate,
                              token: @token.value)

    open_project_headers 'Type' => 'Account'

    send_mail(token.user,
              t(:mail_subject_register, value: Setting.app_title))
  end

  def news_comment_added(user, comment)
    @comment = comment
    @news    = @comment.commented

    open_project_headers 'Project' => @news.project.identifier if @news.project

    message_id @comment, user
    references @news, @comment

    subject = "#{News.model_name.human}: #{@news.title}"
    subject = "Re: [#{@news.project.name}] #{subject}" if @news.project

    send_mail(user, subject)
  end

  def wiki_content_added(user, wiki_content)
    @wiki_content = wiki_content

    open_project_wiki_headers @wiki_content
    message_id @wiki_content, user

    send_mail(user,
              "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_added, id: @wiki_content.page.title)}")
  end

  def wiki_content_updated(user, wiki_content)
    @wiki_content  = wiki_content
    @wiki_diff_url = url_for(controller: '/wiki',
                             action: :diff,
                             project_id: wiki_content.project,
                             id: wiki_content.page.slug,
                             version: wiki_content.version)

    open_project_wiki_headers @wiki_content
    message_id @wiki_content, user

    send_mail(user,
              "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_updated, id: @wiki_content.page.title)}")
  end

  def message_posted(user, message)
    @message = message

    open_project_message_headers(@message)
    message_id @message, user
    references *[@message.parent, @message].compact

    send_mail(user,
              "[#{@message.forum.project.name} - #{@message.forum.name} - msg#{@message.root.id}] #{@message.subject}")
  end

  def account_activated(user)
    @user = user

    open_project_headers 'Type' => 'Account'

    send_mail(user,
              t(:mail_subject_register, value: Setting.app_title))
  end

  def account_information(user, password)
    @user     = user
    @password = password

    open_project_headers 'Type' => 'Account'

    send_mail(user,
              t(:mail_subject_register, value: Setting.app_title))
  end

  def account_activation_requested(admin, user)
    @user           = user
    @activation_url = url_for(controller: '/users',
                              action: :index,
                              status: 'registered',
                              sort: 'created_at:desc')

    open_project_headers 'Type' => 'Account'

    send_mail(admin,
              t(:mail_subject_account_activation_request, value: Setting.app_title))
  end

  ##
  # E-Mail to inform admin about a failed account activation due to the user limit.
  #
  # @param [String] user_email E-Mail of user who could not activate their account.
  # @param [User] admin Admin to be notified of this issue.
  def activation_limit_reached(user_email, admin)
    @email = user_email

    send_mail(admin, t("mail_user_activation_limit_reached.subject"))
  end

  ##
  # E-Mail sent to a user when they tried sending an email to OpenProject to create or update
  # a work package, or forum message for instance.
  #
  # @param [User] user User who sent the email
  # @param [Object] mail The mail object prepared by the mail handler
  # @param [Array<String>] logs List of logs collected during processing of the email
  def incoming_email_error(user, mail, logs)
    @user = user
    @logs = logs
    @mail_from = mail[:from]
    @received_at = DateTime.now
    @incoming_text = mail[:text]
    @quote = mail[:quote]

    headers['References'] = ["<#{mail[:message_id]}>"]
    headers['In-Reply-To'] = ["<#{mail[:message_id]}>"]

    send_mail user, mail[:subject].present? ? "Re: #{mail[:subject]}" : I18n.t("mail_subject_incoming_email_error")
  end

  private

  def open_project_wiki_headers(wiki_content)
    open_project_headers 'Project' => wiki_content.project.identifier,
                         'Wiki-Page-Id' => wiki_content.page.id,
                         'Type' => 'Wiki'
  end

  def open_project_message_headers(message)
    open_project_headers 'Project' => message.project.identifier,
                         'Message-Id' => message.parent_id || message.id,
                         'Type' => 'Forum'
  end
end
