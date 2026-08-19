# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
module IncomingEmails
  class DispatchService
    include ActionView::Helpers::SanitizeHelper

    REFERENCES_RE = %r{^<?op\.([a-z_]+)-(\d+)@}

    AUTOMATIC_HEADERS = {
      "X-Auto-Response-Suppress" => "oof",
      "Auto-Submitted" => /\Aauto-/
    }.freeze

    # Registry for mail handlers
    def self.handlers
      @handlers ||= [
        IncomingEmails::Handlers::MeetingResponse,
        IncomingEmails::Handlers::MessageReply,
        IncomingEmails::Handlers::WorkPackage
      ]
    end

    def self.register_handler(handler_class)
      handlers.unshift(handler_class)
    end

    def self.remove_handler(handler_class)
      handlers.delete(handler_class)
    end

    attr_reader :email, :sender_email, :user, :options, :success, :logs

    def initialize(email, options:)
      @email = email
      @options = assign_options(options)
      @sender_email = email.from.to_a.first.to_s.strip
      @automated_email ||= automatic_header_present?
      @logs = []
    end

    def automated_email? = !!@automated_email

    def call!
      return if ignore_mail?

      determine_actor

      # We only dispatch the action if a user has been accepted or created
      dispatch if user.present?
    ensure
      report_errors unless @success
    end

    private

    # Dispatches the mail to the most appropriate handler:
    # * Iterates through registered handlers to find one that can handle the email
    # * We currently choose the first handler that accepts the mail. In the future, this might need to change
    # * Uses the references header to determine the target object type and ID
    #
    # OpenProject includes the necessary references in the References header of outgoing mail (see ApplicationMailer).
    # This stretches the standard in that the values do not reference existing mails but it has the advantage of being able
    # identify the object the response is destined for without human interference. Email clients will not remove
    # entries from the References header but only add to it.
    #
    # OpenProject also sets the Message-ID header but gateways such as postmark, unless explicitly instructed otherwise,
    # will use their own Message-ID and overwrite the provided one. As an email client includes the value thereof
    # in the In-Reply-To and in the References header the Message-ID could also have been used.
    #
    # Relying on the subject of the mail, which had been implemented before, is brittle as it relies on the user not altering
    # the subject. Additionally, the subject structure might change, e.g. via localization changes.
    def dispatch
      call = call_matching_handler
      return if call.nil?

      @success = call.success?
      log_handler_call(call)

      call.result
    rescue ActiveRecord::RecordInvalid => e
      log "could not save record: #{e.message}", :error
    rescue MissingInformation => e
      log "missing information from #{user}: #{e.message}", :error
    rescue UnauthorizedAction
      log "unauthorized attempt from #{user}", :error
    end

    def log_handler_call(call)
      log_type = call.message_type == :notice ? :info : call.message_type
      log(call.message, log_type) if call.message.present?
    end

    ##
    # Find a matching handler to handle the email and call it.
    def call_matching_handler
      handler = instantiate_matching_handler

      if handler.present?
        handler.process
      else
        log "No matching handler found for email #{email.message_id} from #{user}",
            :info,
            report: false

        nil
      end
    end

    ##
    # Find a matching handler class for the given email headers
    def instantiate_matching_handler
      reference = object_reference_from_header

      # Instantiate the first handler that can handle this email
      self
        .class
        .handlers
        .find { |h| h.handles?(email, reference:, automated_email: automated_email?) }
        &.new(email, user:, plain_text_body:, reference:, options:)
    end

    ##
    # Determine the actor for the email processing.
    # If the user is not found, we will handle using the given unkown_user option
    def determine_actor
      if sender_email.present?
        @user = User.find_by_mail(sender_email)
      end

      # If the user is still not set, we have to deal with an unkonwn user
      if user.nil?
        handle_unknown_user
      end
    end

    def handle_unknown_user
      case options[:unknown_user]
      when "accept"
        @user = User.anonymous
      when "create"
        @user, password = UserCreator.create_user_from_email(email)
        if @user
          log "[#{@user.login}] account created"
          UserMailer.account_information(@user, password).deliver_later
        else
          log "could not create account for [#{sender_email}]", :error
        end
      else
        # Default behaviour, emails from unknown users are ignored
        log "ignoring email from unknown user [#{sender_email}]", report: false
      end
    end

    def report_errors
      return if automated_email?
      return unless Setting.report_incoming_email_errors?
      return if logs.empty?

      UserMailer.incoming_email_error(user, mail_as_hash(email), logs).deliver_later
    end

    def mail_as_hash(email)
      {
        message_id: email.message_id,
        subject: email.subject,
        from: email.from&.first || "(unknown from address)",
        quote: incoming_email_quote(email),
        text: plain_text_body || incoming_email_text(email)
      }
    end

    def incoming_email_text(mail)
      mail.text_part.present? ? mail.text_part.body.to_s : mail.body.to_s
    end

    def incoming_email_quote(mail)
      quote = incoming_email_text(mail)
      quoted = String(quote).lines.join("> ")

      "> #{quoted}"
    end

    def ignore_mail?
      mail_from_system? || ignored_user?
    end

    def mail_from_system?
      # Ignore emails received from the application emission address to avoid hell cycles
      if system_mail_addresses.include?(sender_email.downcase)
        log "ignoring email from emission address [#{sender_email}]", report: false
        # don't report back errors to ourselves
        return true
      end

      false
    end

    def system_mail_addresses
      [
        ApplicationMailer.mail_from,
        ApplicationMailer.reply_to_address
      ]
        .map { |mail| mail.to_s.strip.downcase }
    end

    def automatic_header_present?
      AUTOMATIC_HEADERS.each do |key, ignored_value|
        value = email.header[key]
        next if value.blank?

        value = value.to_s.downcase
        if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
          log "email has automated #{key}:#{value} header", report: false
          return true
        end
      end

      false
    end

    def ignored_user?
      return false if @user.nil?

      unless @user.active?
        log "ignoring email from non-active user [#{@user.login}]"
        true
      end
    end

    # Find a matching object reference in the mail's references header.
    # We set this header in outgoing emails to include an encoded reference to the object
    def object_reference_from_header
      headers = [email.references].flatten.compact
      if headers.reverse.detect { |h| h.to_s =~ REFERENCES_RE }
        klass = $1
        id = $2.to_i
        { klass:, id: }
      else
        {}
      end
    end

    def log(message, level = :info, report: true)
      logs << "#{level}: #{message}" if report

      message = "MailHandler: #{message}"
      Rails.logger.public_send(level, message)
      nil
    end

    def assign_options(value) # rubocop:disable Metrics/AbcSize
      options = value.dup

      options[:issue] ||= {}
      options[:allow_override] = allow_override_option(options).to_set(&:to_sym)
      # Project needs to be overridable if not specified
      options[:allow_override] << :project unless options[:issue].has_key?(:project)
      # Status overridable by default
      options[:allow_override] << :status unless options[:issue].has_key?(:status)
      # Version overridable by default
      options[:allow_override] << :version unless options[:issue].has_key?(:version)
      # Type overridable by default
      options[:allow_override] << :type unless options[:issue].has_key?(:type)
      # Priority overridable by default
      options[:allow_override] << :priority unless options[:issue].has_key?(:priority)

      options[:no_permission_check] = ActiveRecord::Type::Boolean.new.cast(options[:no_permission_check])

      options
    end

    def allow_override_option(options)
      if options[:allow_override].is_a?(String)
        options[:allow_override].split(",").map(&:strip)
      else
        options[:allow_override] || []
      end
    end

    # Returns the text/plain part of the email
    # If not found (eg. HTML-only email), returns the body with tags removed
    def plain_text_body
      return @plain_text_body unless @plain_text_body.nil?

      part = email.text_part || email.html_part || email
      @plain_text_body = Redmine::CodesetUtil.to_utf8(part.body.decoded, part.charset)

      # strip html tags and remove doctype directive
      # Note: In Rails 5, `strip_tags` also encodes HTML entities
      @plain_text_body = strip_tags(@plain_text_body.strip)
      @plain_text_body = CGI.unescapeHTML(@plain_text_body)

      @plain_text_body.sub! %r{^<!DOCTYPE .*$}, ""
      @plain_text_body
    end
  end
end
