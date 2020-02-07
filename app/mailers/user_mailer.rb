#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class UserMailer < BaseMailer

  def test_mail(user)
    @welcome_url = url_for(controller: '/homescreen')

    headers['X-OpenProject-Type'] = 'Test'

    with_locale_for(user) do
      mail to: "\"#{user.name}\" <#{user.mail}>", subject: 'OpenProject Test'
    end
  end

  def work_package_added(user, journal, author)
    User.execute_as user do
      work_package = journal.journable.reload
      @issue = work_package # instance variable is used in the view
      @journal = journal

      set_work_package_headers(work_package)

      message_id work_package, user

      with_locale_for(user) do
        mail_for_author author, to: user.mail, subject: subject_for_work_package(work_package)
      end
    end
  end

  def work_package_updated(user, journal, author = User.current)
    User.execute_as user do
      work_package = journal.journable.reload

      # instance variables are used in the view
      @issue = work_package
      @journal = journal

      set_work_package_headers(work_package)

      message_id journal, user
      references work_package, user

      with_locale_for(user) do
        mail_for_author author, to: user.mail, subject: subject_for_work_package(work_package)
      end
    end
  end

  def work_package_watcher_changed(work_package, user, watcher_changer, action)
    User.execute_as user do
      @issue = work_package
      @watcher_changer = watcher_changer
      @action = action

      set_work_package_headers(work_package)
      message_id work_package, user
      references work_package, user

      with_locale_for(user) do
        mail to: user.mail, subject: subject_for_work_package(work_package)
      end
    end
  end

  def password_lost(token)
    return unless token.user # token's can have no user

    @token = token
    @reset_password_url = url_for(controller: '/account',
                                  action:     :lost_password,
                                  token:      @token.value)

    open_project_headers 'Type' => 'Account'

    user = @token.user
    with_locale_for(user) do
      subject = t(:mail_subject_lost_password, value: Setting.app_title)
      mail to: user.mail, subject: subject
    end
  end

  def copy_project_failed(user, source_project, target_project_name, errors)
    @source_project = source_project
    @target_project_name = target_project_name
    @errors = errors

    open_project_headers 'Source-Project' => source_project.identifier,
                         'Author'         => user.login

    message_id source_project, user

    with_locale_for(user) do
      subject = I18n.t('copy_project.failed', source_project_name: source_project.name)

      mail to: user.mail, subject: subject
    end
  end

  def copy_project_succeeded(user, source_project, target_project, errors)
    @source_project = source_project
    @target_project = target_project
    @errors = errors

    open_project_headers 'Source-Project' => source_project.identifier,
                         'Target-Project' => target_project.identifier,
                         'Author'         => user.login

    message_id target_project, user

    with_locale_for(user) do
      subject = I18n.t('copy_project.succeeded', target_project_name: target_project.name)

      mail to: user.mail, subject: subject
    end
  end

  def news_added(user, news, author)
    @news = news

    open_project_headers 'Type'    => 'News'
    open_project_headers 'Project' => @news.project.identifier if @news.project

    message_id @news, user

    with_locale_for(user) do
      subject = "#{News.model_name.human}: #{@news.title}"
      subject = "[#{@news.project.name}] #{subject}" if @news.project
      mail_for_author author, to: user.mail, subject: subject
    end
  end

  def user_signed_up(token)
    return unless token.user

    @token = token
    @activation_url = url_for(controller: '/account',
                              action:     :activate,
                              token:      @token.value)

    open_project_headers 'Type' => 'Account'

    user = token.user
    with_locale_for(user) do
      subject = t(:mail_subject_register, value: Setting.app_title)
      mail to: user.mail, subject: subject
    end
  end

  def news_comment_added(user, comment, author)
    @comment = comment
    @news    = @comment.commented

    open_project_headers 'Project' => @news.project.identifier if @news.project

    message_id @comment, user
    references @news, user

    with_locale_for(user) do
      subject = "#{News.model_name.human}: #{@news.title}"
      subject = "Re: [#{@news.project.name}] #{subject}" if @news.project
      mail_for_author author, to: user.mail, subject: subject
    end
  end

  def wiki_content_added(user, wiki_content, author)
    @wiki_content = wiki_content

    open_project_headers 'Project'      => @wiki_content.project.identifier,
                         'Wiki-Page-Id' => @wiki_content.page.id,
                         'Type'         => 'Wiki'

    message_id @wiki_content, user

    with_locale_for(user) do
      subject = "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_added, id: @wiki_content.page.title)}"
      mail_for_author author, to: user.mail, subject: subject
    end
  end

  def wiki_content_updated(user, wiki_content, author)
    @wiki_content  = wiki_content
    @wiki_diff_url = url_for(controller: '/wiki',
                             action:     :diff,
                             project_id: wiki_content.project,
                             id:         wiki_content.page.slug,
                             version:    wiki_content.version)

    open_project_headers 'Project'      => @wiki_content.project.identifier,
                         'Wiki-Page-Id' => @wiki_content.page.id,
                         'Type'         => 'Wiki'

    message_id @wiki_content, user

    with_locale_for(user) do
      subject = "[#{@wiki_content.project.name}] #{t(:mail_subject_wiki_content_updated, id: @wiki_content.page.title)}"
      mail_for_author author, to: user.mail, subject: subject
    end
  end

  def message_posted(user, message, author)
    @message     = message
    @message_url = topic_url(@message.root, r: @message.id, anchor: "message-#{@message.id}")

    open_project_headers 'Project'      => @message.project.identifier,
                         'Wiki-Page-Id' => @message.parent_id || @message.id,
                         'Type'         => 'Forum'

    message_id @message, user
    references @message.parent, user if @message.parent

    with_locale_for(user) do
      subject = "[#{@message.forum.project.name} - #{@message.forum.name} - msg#{@message.root.id}] #{@message.subject}"
      mail_for_author author, to: user.mail, subject: subject
    end
  end

  def account_activated(user)
    @user = user

    open_project_headers 'Type' => 'Account'

    with_locale_for(user) do
      subject = t(:mail_subject_register, value: Setting.app_title)
      mail to: user.mail, subject: subject
    end
  end

  def account_information(user, password)
    @user     = user
    @password = password

    open_project_headers 'Type' => 'Account'

    with_locale_for(user) do
      subject = t(:mail_subject_register, value: Setting.app_title)
      mail to: user.mail, subject: subject
    end
  end

  def account_activation_requested(admin, user)
    @user           = user
    @activation_url = url_for(controller: '/users',
                              action:     :index,
                              status:     'registered',
                              sort:       'created_at:desc')

    open_project_headers 'Type' => 'Account'

    with_locale_for(admin) do
      subject = t(:mail_subject_account_activation_request, value: Setting.app_title)
      mail to: admin.mail, subject: subject
    end
  end

  def reminder_mail(user, issues, days, group = nil)
    @issues = issues
    @days   = days
    @group  = group

    assigned_to_id = if group
                       group.id
                     else
                       user.id
                     end

    @assigned_issues_url = url_for(controller: :work_packages,
                                   action: :index,
                                   query_props: '{"t":"dueDate:asc","f":[{"n":"status","o":"o","v":[]},{"n":"assignee","o":"=","v":["' + assigned_to_id.to_s + '"]},{"n":"dueDate","o":"<t+","v":["2"]}]}')

    open_project_headers 'Type' => 'Issue'

    with_locale_for(user) do
      subject = if @group
                  t(:mail_subject_group_reminder, count: @issues.size, days: @days, group: @group.groupname)
                else
                  t(:mail_subject_reminder, count: @issues.size, days: @days)
                end
      mail to: user.mail, subject: subject
    end
  end

  ##
  # E-Mail to inform admin about a failed account activation due to the user limit.
  #
  # @param [String] user_email E-Mail of user who could not activate their account.
  # @param [User] admin Admin to be notified of this issue.
  def activation_limit_reached(user_email, admin)
    @email = user_email

    with_locale_for(admin) do
      mail to: admin.mail, subject: t("mail_user_activation_limit_reached.subject")
    end
  end

  private

  def subject_for_work_package(wp)
    "#{wp.project.name} - #{wp.status.name} #{wp.type.name} ##{wp.id}: #{wp.subject}"
  end

  # like #mail, but contains special author based filters
  # currently only:
  #  - remove_self_notifications
  # might be refactored at a later time to be as generic as Interceptors
  def mail_for_author(author, headers = {}, &block)
    message = mail headers, &block

    self.class.remove_self_notifications(message, author)

    message
  end

  def references(object, user)
    headers['References'] = "<#{self.class.generate_message_id(object, user)}>"
  end

  def set_work_package_headers(work_package)
    open_project_headers 'Project'        => work_package.project.identifier,
                         'Issue-Id'       => work_package.id,
                         'Issue-Author'   => work_package.author.login,
                         'Type'           => 'WorkPackage'

    if work_package.assigned_to
      open_project_headers 'Issue-Assignee' => work_package.assigned_to.login
    end
  end
end

##
# Interceptors
#
# These are registered in config/initializers/register_mail_interceptors.rb
#
# Unfortunately, this results in changes on the interceptor classes during development mode
# not being reflected until a server restart.

class DefaultHeadersInterceptor
  def self.delivering_email(mail)
    mail.headers(default_headers)
  end

  def self.default_headers
    {
      'X-Mailer'           => 'OpenProject',
      'X-OpenProject-Host' => Setting.host_name,
      'X-OpenProject-Site' => Setting.app_title,
      'Precedence'         => 'bulk',
      'Auto-Submitted'     => 'auto-generated'
    }
  end
end

class DoNotSendMailsWithoutReceiverInterceptor
  def self.delivering_email(mail)
    receivers = [mail.to, mail.cc, mail.bcc]
    # the above fields might be empty arrays (if entries have been removed
    # by another interceptor) or nil, therefore checking for blank?
    mail.perform_deliveries = false if receivers.all?(&:blank?)
  end
end
