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

class MailHandler < ActionMailer::Base
  include ActionView::Helpers::SanitizeHelper
  include Redmine::I18n

  class UnauthorizedAction < StandardError; end

  class MissingInformation < StandardError; end

  attr_reader :email, :sender_email, :user, :options, :logs

  def initialize
    super

    @result = false
    @logs = []
  end

  ##
  # Code copied from base class and extended with optional options parameter
  # as well as force_encoding support.
  def self.receive(raw_mail, options = {})
    raw_mail.force_encoding("ASCII-8BIT") if raw_mail.respond_to?(:force_encoding)

    ActiveSupport::Notifications.instrument("receive.action_mailer") do |payload|
      mail = Mail.new(raw_mail)
      set_payload_for_mail(payload, mail)
      with_options(options).receive(mail)
    end
  end

  def self.with_options(options)
    handler = new

    handler.options = options

    handler
  end

  cattr_accessor :ignored_emails_headers
  @@ignored_emails_headers = {
    "X-Auto-Response-Suppress" => "oof",
    "Auto-Submitted" => /\Aauto-/
  }

  # Processes incoming emails
  # Returns the created object (eg. an issue, a message) or false
  def receive(email)
    @email = email
    @sender_email = email.from.to_a.first.to_s.strip
    # Ignore emails received from the application emission address to avoid hell cycles
    if sender_email.downcase == Setting.mail_from.to_s.strip.downcase
      log "ignoring email from emission address [#{sender_email}]", report: false
      # don't report back errors to ourselves
      return false
    end
    # Ignore auto generated emails
    self.class.ignored_emails_headers.each do |key, ignored_value|
      value = email.header[key]
      if value
        value = value.to_s.downcase
        if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
          log "ignoring email with #{key}:#{value} header", report: false
          # no point reporting back in case of auto-generated emails
          return false
        end
      end
    end

    @user = User.find_by_mail(sender_email) if sender_email.present?
    if @user && !@user.active?
      log "ignoring email from non-active user [#{@user.login}]"
      return false
    end
    if @user.nil?
      # Email was submitted by an unknown user
      case options[:unknown_user]
      when "accept"
        @user = User.anonymous
      when "create"
        @user, password = MailHandler::UserCreator.create_user_from_email(email)
        if @user
          log "[#{@user.login}] account created"
          UserMailer.account_information(@user, password).deliver_later
        else
          log "could not create account for [#{sender_email}]", :error
          return false
        end
      else
        # Default behaviour, emails from unknown users are ignored
        log "ignoring email from unknown user [#{sender_email}]", report: false
        return false
      end
    end
    User.current = @user
    dispatch
  ensure
    report_errors if !@result && Setting.report_incoming_email_errors?
  end

  def options=(value)
    @options = value.dup

    options[:issue] ||= {}
    options[:allow_override] = allow_override_option(options).map(&:to_sym).to_set
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
    options[:no_permission_check] = options[:no_permission_check].to_s == "1"
  end

  private

  # Dispatches the mail to the most appropriate method:
  # * If there is no References header the email is interpreted as a new work package
  # * If there is a References header the email is interpreted to update an existing entity (e.g. a work package
  #   or a message)
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
    m, object_id = dispatch_target_from_header

    @result = m ? m.call(object_id) : dispatch_to_default
  rescue ActiveRecord::RecordInvalid => e
    log "could not save record: #{e.message}", :error
    false
  rescue MissingInformation => e
    log "missing information from #{user}: #{e.message}", :error
    false
  rescue UnauthorizedAction
    log "unauthorized attempt from #{user}", :error
    false
  end

  # Dispatch the mail to the default method handler, receive_work_package
  #
  # This can be overridden or patched to support handling other incoming
  # email types
  def dispatch_to_default
    receive_work_package
  end

  REFERENCES_RE = %r{^<?op\.([a-z_]+)-(\d+)@}

  ##
  # Find a matching method to dispatch to given the mail's references header.
  # We set this header in outgoing emails to include an encoded reference to the object
  def dispatch_target_from_header
    headers = [email.references].flatten.compact
    if headers.reverse.detect { |h| h.to_s =~ REFERENCES_RE }
      klass = $1
      object_id = $2.to_i
      method_name = :"receive_#{klass}_reply"
      if self.class.private_instance_methods.include?(method_name)
        [method(method_name), object_id]
      end
    end
  end

  # Creates a new work package
  def receive_work_package
    project = target_project

    result = create_work_package(project)

    if result.is_a?(WorkPackage)
      log "work_package ##{result.id} created by #{user}"
      result
    else
      log "work_package could not be created by #{user} due to ##{result.full_messages}", :error
      false
    end
  end

  def receive_journal_reply(journal_id)
    journal = Journal.find_by(id: journal_id)
    return unless journal

    send(:"receive_#{journal.journable_type.underscore}_reply", journal.journable_id)
  end

  # Adds a note to an existing work package
  def receive_work_package_reply(work_package_id)
    work_package = WorkPackage.find_by(id: work_package_id)
    return unless work_package

    # ignore CLI-supplied defaults for new work_packages
    options[:issue].clear

    result = update_work_package(work_package)

    if result.is_a?(WorkPackage)
      log "work_package ##{result.id} updated by #{user}"
      result.last_journal
    else
      log "work_package could not be updated by #{user} due to ##{result.full_messages}", :error
      false
    end
  end

  # Receives a reply to a forum message
  def receive_message_reply(message_id)
    message = Message.find_by(id: message_id)
    if message
      message = message.root

      if !options[:no_permission_check] && !user.allowed_in_project?(:add_messages, message.project)
        raise UnauthorizedAction
      end

      if message.locked?
        log "ignoring reply from [#{sender_email}] to a locked topic"
      else
        reply = Message.new(subject: email.subject.gsub(%r{^.*msg\d+\]}, "").strip,
                            content: cleaned_up_text_body)
        reply.author = user
        reply.forum = message.forum
        message.children << reply
        add_attachments(reply)
        reply
      end
    end
  end

  def add_attachments(container)
    return [] unless email.attachments&.present?

    email
      .attachments
      .reject { |attachment| ignored_filename?(attachment.filename) }
      .filter_map { |attachment| create_attachment(attachment, container) }
  end

  def create_attachment(attachment, container)
    file = OpenProject::Files.create_uploaded_file(
      name: attachment.filename,
      content_type: attachment.mime_type,
      content: attachment.decoded,
      binary: true
    )

    call = ::Attachments::CreateService
      .new(user:)
      .call(container:, filename: attachment.filename, file:)

    call.on_failure do
      log "Failed to add attachment #{attachment.filename} for [#{sender_email}]: #{call.message}"
    end

    call.result
  end

  # Adds To and Cc as watchers of the given object if the sender has the
  # appropriate permission
  def add_watchers(obj)
    if user.allowed_in_project?(:"add_#{obj.class.name.underscore}_watchers", obj.project) ||
       user.allowed_in_project?(:"add_#{obj.class.lookup_ancestors.last.name.underscore}_watchers", obj.project)
      addresses = [email.to, email.cc].flatten.compact.uniq.map { |a| a.strip.downcase }
      unless addresses.empty?
        User
          .active
          .where(["LOWER(mail) IN (?)", addresses])
          .find_each do |user|
          Services::CreateWatcher
            .new(obj, user)
            .run
        end
        # FIXME: somehow the watchable attribute of the new watcher is not set, when the issue is not safed.
        # So we fix that here manually
        obj.watchers.each do |w|
          w.watchable = obj
        end
      end
    end
  end

  def get_keyword(attr, options = {})
    @keywords ||= {}
    if @keywords.has_key?(attr)
      @keywords[attr]
    else
      @keywords[attr] = begin
        if (options[:override] || self.options[:allow_override].include?(attr)) &&
           (v = extract_keyword!(plain_text_body, attr, options[:format]))
          v
        else
          # Return either default or nil
          self.options[:issue][attr]
        end
      end
    end
  end

  # Destructively extracts the value for +attr+ in +text+
  # Returns nil if no matching keyword found
  def extract_keyword!(text, attr, format)
    keys = human_attr_translations(attr)
             .compact_blank
             .uniq
             .map { |k| Regexp.escape(k) }

    value = nil

    text.gsub!(/^(#{keys.join('|')})[ \t]*:[ \t]*(?<value>#{format || '.+'})\s*$/i) do |_|
      value = Regexp.last_match[:value]&.strip

      ""
    end

    value
  end

  def human_attr_translations(attr)
    keys = [attr.to_s.humanize]

    [user&.language, Setting.default_language].compact_blank.each do |lang|
      keys << all_attribute_translations(lang)[attr]
    end

    keys
  end

  def target_project
    # TODO: other ways to specify project:
    # * parse the email To field
    # * specific project (eg. Setting.mail_handler_target_project)
    target = Project.find_by(identifier: get_keyword(:project))
    raise MissingInformation.new("Unable to determine target project") if target.nil?

    target
  end

  # Returns a Hash of issue attributes extracted from keywords in the email body
  def wp_attributes_from_keywords(work_package)
    {
      "assigned_to_id" => wp_assignee_from_keywords(work_package),
      "category_id" => wp_category_from_keywords(work_package),
      "due_date" => wp_due_date_from_keywords,
      "estimated_hours" => wp_estimated_hours_from_keywords,
      "parent_id" => wp_parent_from_keywords,
      "priority_id" => wp_priority_from_keywords,
      "remaining_hours" => wp_remaining_hours_from_keywords,
      "responsible_id" => wp_accountable_from_keywords(work_package),
      "start_date" => wp_start_date_from_keywords,
      "status_id" => wp_status_from_keywords,
      "type_id" => wp_type_from_keywords(work_package),
      "version_id" => wp_version_from_keywords(work_package)
    }.compact_blank!
  end

  # Returns a Hash of issue custom field values extracted from keywords in the email body
  def custom_field_values_from_keywords(customized)
    "#{customized.class.name}CustomField".constantize.all.inject({}) do |h, v|
      if value = get_keyword(v.name, override: true)
        h[v.id.to_s] = v.value_of value
      end
      h
    end
  end

  def lookup_case_insensitive_key(scope, attribute, column_name = Arel.sql("name"))
    if k = get_keyword(attribute)
      scope.find_by("lower(#{column_name}) = ?", k.downcase).try(:id)
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

  def cleaned_up_text_body
    cleanup_body(plain_text_body)
  end

  def self.full_sanitizer
    @full_sanitizer ||= Rails::Html::FullSanitizer.new
  end

  def allow_override_option(options)
    if options[:allow_override].is_a?(String)
      options[:allow_override].split(",").map(&:strip)
    else
      options[:allow_override] || []
    end
  end

  # Removes the email body of text after the truncation configurations.
  def cleanup_body(body)
    delimiters = Setting.mail_handler_body_delimiters.to_s.split(/[\r\n]+/).compact_blank.map { |s| Regexp.escape(s) }
    unless delimiters.empty?
      regex = Regexp.new("^[> ]*(#{delimiters.join('|')})\s*[\r\n].*", Regexp::MULTILINE)
      body = body.gsub(regex, "")
    end

    regex_delimiter = Setting.mail_handler_body_delimiter_regex
    if regex_delimiter.present?
      regex = Regexp.new(regex_delimiter, Regexp::MULTILINE)
      body = body.gsub(regex, "")
    end

    body.strip
  end

  def ignored_filenames
    @ignored_filenames ||= Setting.mail_handler_ignore_filenames.to_s.split(/[\r\n]+/).compact_blank
  end

  def ignored_filename?(filename)
    ignored_filenames.any? do |line|
      filename.match? Regexp.escape(line)
    end
  end

  def create_work_package(project)
    work_package = WorkPackage.new(project:)
    attributes = collect_wp_attributes_from_email_on_create(work_package)

    service_call = WorkPackages::CreateService
                   .new(user:,
                        contract_class: work_package_create_contract_class)
                   .call(**attributes.merge(work_package:).symbolize_keys)

    if service_call.success?
      work_package = service_call.result

      add_watchers(work_package)
      add_attachments(work_package)

      work_package
    else
      service_call.errors
    end
  end

  def collect_wp_attributes_from_email_on_create(work_package)
    attributes = wp_attributes_from_keywords(work_package)
    attributes
      .merge("custom_field_values" => custom_field_values_from_keywords(work_package),
             "subject" => email.subject.to_s.chomp[0, 255] || "(no subject)",
             "description" => cleaned_up_text_body)
  end

  def update_work_package(work_package)
    attributes = collect_wp_attributes_from_email_on_update(work_package)
    attributes[:attachment_ids] = work_package.attachment_ids + add_attachments(work_package).map(&:id)

    service_call = WorkPackages::UpdateService
                   .new(user:,
                        model: work_package,
                        contract_class: work_package_update_contract_class)
                   .call(**attributes.symbolize_keys)

    if service_call.success?
      service_call.result
    else
      service_call.errors
    end
  end

  def collect_wp_attributes_from_email_on_update(work_package)
    attributes = wp_attributes_from_keywords(work_package)
    attributes
      .merge("custom_field_values" => custom_field_values_from_keywords(work_package),
             "journal_notes" => cleaned_up_text_body)
  end

  def wp_type_from_keywords(work_package)
    lookup_case_insensitive_key(work_package.project.types, :type) ||
      (work_package.new_record? && work_package.project.types.first.try(:id))
  end

  def wp_status_from_keywords
    lookup_case_insensitive_key(Status, :status)
  end

  def wp_parent_from_keywords
    get_keyword(:parent)
  end

  def wp_priority_from_keywords
    lookup_case_insensitive_key(IssuePriority, :priority)
  end

  def wp_category_from_keywords(work_package)
    lookup_case_insensitive_key(work_package.project.categories, :category)
  end

  def wp_accountable_from_keywords(work_package)
    get_assignable_principal_from_keywords(:responsible, work_package)
  end

  def wp_assignee_from_keywords(work_package)
    get_assignable_principal_from_keywords(:assigned_to, work_package)
  end

  def get_assignable_principal_from_keywords(keyword, work_package)
    keyword = get_keyword(keyword, override: true)

    return nil if keyword.blank?

    Principal.possible_assignee(work_package.project).where(id: Principal.like(keyword)).first.try(:id)
  end

  def wp_version_from_keywords(work_package)
    lookup_case_insensitive_key(work_package.project.shared_versions, :version, Arel.sql("#{Version.table_name}.name"))
  end

  def wp_start_date_from_keywords
    get_keyword(:start_date, override: true, format: '\d{4}-\d{2}-\d{2}')
  end

  def wp_due_date_from_keywords
    get_keyword(:due_date, override: true, format: '\d{4}-\d{2}-\d{2}')
  end

  def wp_estimated_hours_from_keywords
    get_keyword(:estimated_hours, override: true)
  end

  def wp_remaining_hours_from_keywords
    get_keyword(:remaining_hours, override: true)
  end

  def log(message, level = :info, report: true)
    logs << "#{level}: #{message}" if report

    message = "MailHandler: #{message}"
    logger.public_send(level, message)
  end

  def report_errors
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

  def work_package_create_contract_class
    if options[:no_permission_check]
      CreateWorkPackageWithoutAuthorizationsContract
    else
      WorkPackages::CreateContract
    end
  end

  def work_package_update_contract_class
    if options[:no_permission_check]
      UpdateWorkPackageWithoutAuthorizationsContract
    else
      WorkPackages::UpdateContract
    end
  end

  class UpdateWorkPackageWithoutAuthorizationsContract < WorkPackages::UpdateContract
    include WorkPackages::SkipAuthorizationChecks
  end

  class CreateWorkPackageWithoutAuthorizationsContract < WorkPackages::CreateContract
    include WorkPackages::SkipAuthorizationChecks
  end
end
