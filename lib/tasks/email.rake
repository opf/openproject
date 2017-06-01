#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :redmine do
  namespace :email do
    desc <<-END_DESC
Read an email from standard input.

General options:
  unknown_user=ACTION      how to handle emails from an unknown user
                           ACTION can be one of the following values:
                           ignore: email is ignored (default)
                           accept: accept as anonymous user
                           create: create a user account
  no_permission_check=1    disable permission checking when receiving
                           the email

Issue attributes control options:
  project=PROJECT          identifier of the target project
  status=STATUS            name of the target status
  type=TYPE                name of the target type
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  allow_override=ATTRS     allow email content to override attributes
                           specified by previous options
                           ATTRS is a comma separated list of attributes

If you want to set default values for custom fields, set the value similar to
the attributes above, using the name of the custom field as a key.
Custom ields set this way can only contain characters valid for environment
variables, i.e. no punctuation and no whitespace.
Additionally, you need to set the list of the attributes set this way in the
default_attributes list like this:

  default_attributes="CustomField1 CustomField2"

Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:
  rake redmine:email:read RAILS_ENV="production" < raw_email

  # Fixed project and default type specified, but emails can override
  # both type and priority attributes:
  rake redmine:email:read RAILS_ENV="production" \\
                  project=foo \\
                  type=bug \\
                  allow_override=type,priority < raw_email
END_DESC

    task read: :environment do
      MailHandler.receive(STDIN.read, options_from_env)
    end

    desc <<-END_DESC
Read emails from an IMAP server.

General options:
  unknown_user=ACTION      how to handle emails from an unknown user
                           ACTION can be one of the following values:
                           ignore: email is ignored (default)
                           accept: accept as anonymous user
                           create: create a user account
  no_permission_check=1    disable permission checking when receiving
                           the email

Available IMAP options:
  host=HOST                IMAP server host (default: 127.0.0.1)
  port=PORT                IMAP server port (default: 143)
  ssl=SSL                  Use SSL? (default: false)
  username=USERNAME        IMAP account
  password=PASSWORD        IMAP password
  folder=FOLDER            IMAP folder to read (default: INBOX)

Issue attributes control options:
  project=PROJECT          identifier of the target project
  status=STATUS            name of the target status
  type=TYPE                name of the target type
  category=CATEGORY        name of the target category
  priority=PRIORITY        name of the target priority
  allow_override=ATTRS     allow email content to override attributes
                           specified by previous options
                           ATTRS is a comma separated list of attributes

If you want to set default values for custom fields, set the value similar to
the attributes above, using the name of the custom field as a key.
Custom ields set this way can only contain characters valid for environment
variables, i.e. no punctuation and no whitespace.
Additionally, you need to set the list of the attributes set this way in the
default_attributes list like this:

  default_attributes="CustomField1 CustomField2"

Processed emails control options:
  move_on_success=MAILBOX  move emails that were successfully received
                           to MAILBOX instead of deleting them
  move_on_failure=MAILBOX  move emails that were ignored to MAILBOX

Examples:
  # No project specified. Emails MUST contain the 'Project' keyword:

  rake redmine:email:receive_iamp RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@example.net password=xxx


  # Fixed project and default type specified, but emails can override
  # both type and priority attributes:

  rake redmine:email:receive_imap RAILS_ENV="production" \\
    host=imap.foo.bar username=redmine@example.net password=xxx ssl=1 \\
    project=foo \\
    type=bug \\
    allow_override=type,priority
END_DESC

    task receive_imap: :environment do
      imap_options = { host: ENV['host'],
                       port: ENV['port'],
                       ssl: ENV['ssl'],
                       ssl_verification: !['0', 'false', 'f'].include?(ENV['ssl_verification']),
                       username: ENV['username'],
                       password: ENV['password'],
                       folder: ENV['folder'],
                       move_on_success: ENV['move_on_success'],
                       move_on_failure: ENV['move_on_failure'] }

      Redmine::IMAP.check(imap_options, options_from_env)
    end

    desc <<-END_DESC
Read emails from an POP3 server.

Available POP3 options:
  host=HOST                POP3 server host (default: 127.0.0.1)
  port=PORT                POP3 server port (default: 110)
  username=USERNAME        POP3 account
  password=PASSWORD        POP3 password
  apop=1                   use APOP authentication (default: false)
  delete_unprocessed=1     delete messages that could not be processed
                           successfully from the server (default
                           behaviour is to leave them on the server)

See redmine:email:receive_imap for more options and examples.
END_DESC

    task receive_pop3: :environment do
      pop_options  = { host: ENV['host'],
                       port: ENV['port'],
                       apop: ENV['apop'],
                       username: ENV['username'],
                       password: ENV['password'],
                       delete_unprocessed: ENV['delete_unprocessed'] }

      Redmine::POP3.check(pop_options, options_from_env)
    end

    desc 'Send a test email to the user with the provided login name'
    task :test, [:login] => :environment do |_task, args|
      login = args[:login]
      if login.blank?
        abort I18n.t(:notice_email_error, default: 'Please include the user login to test with. Example: redmine:email:test[example-login]')
      end

      user = User.find_by_login(login)
      unless user && user.logged?
        abort I18n.t(:notice_email_error, default: "User with login '#{login}' not found")
      end

      ActionMailer::Base.raise_delivery_errors = true

      begin
        UserMailer.test_mail(user).deliver_now
        puts I18n.t(:notice_email_sent, value: user.mail)
      rescue => e
        abort I18n.t(:notice_email_error, e.message)
      end
    end

    private

    def options_from_env
      { issue: {} }.tap do |options|
        default_fields = (ENV['default_fields'] || '').split
        default_fields |= %w[project status type category priority assigned_to fixed_version]
        default_fields.each do |field| options[:issue][field.to_sym] = ENV[field] if ENV[field] end

        options[:allow_override] = ENV['allow_override'] if ENV['allow_override']
        options[:unknown_user] = ENV['unknown_user'] if ENV['unknown_user']
        options[:no_permission_check] = ENV['no_permission_check'] if ENV['no_permission_check']
      end
    end
  end
end
