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
module IncomingEmails::Handlers
  class Base
    attr_reader :email, :user, :reference, :options, :plain_text_body

    def initialize(email, user:, reference:, plain_text_body:, options:)
      @reference = reference
      @user = user
      @options = options
      @email = email
      @plain_text_body = plain_text_body
    end

    # Override in subclasses to determine if this handler can process the email
    def self.handles?(email, reference:, automated_email:)
      raise SubclassResponsibilityError, "Subclasses must implement handles? method"
    end

    # Override in subclasses to process the email
    def process
      raise SubclassResponsibilityError, "Subclasses must implement process method"
    end

    def cleaned_up_text_body
      cleanup_body(plain_text_body)
    end

    protected

    # The receive_* methods have been moved to specific handler classes:
    # - MailHandler::WorkPackage for work package related functionality
    # - MailHandler::MessageReply for message reply functionality

    def add_attachments(container)
      return [] if email.attachments.blank?

      email
        .attachments
        .reject { |attachment| ignored_filename?(attachment.filename) }
        .filter_map { |attachment| create_attachment(attachment, container) }
    end

    def ignored_filenames
      @ignored_filenames ||= Setting.mail_handler_ignore_filenames.to_s.split(/[\r\n]+/).compact_blank
    end

    def ignored_filename?(filename)
      ignored_filenames.any? do |line|
        filename.match? Regexp.escape(line)
      end
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
    def add_watchers(obj) # rubocop:disable Metrics/AbcSize
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
      keys = [
        attr.to_s,
        attr.to_s.humanize
      ]

      [user.language, Setting.default_language].compact_blank.each do |lang|
        keys << all_attribute_translations(lang)[attr]
      end

      keys
    end

    def all_attribute_translations(lang)
      @all_attribute_translations ||= {}
      @all_attribute_translations[lang] ||= begin
        translations = {}

        # Work package attribute translations
        I18n.with_locale(lang) do
          %i[assigned_to category due_date estimated_hours parent priority
             remaining_hours responsible start_date status type version project].each do |attr|
            translations[attr] = ::WorkPackage.human_attribute_name(attr)
          end
        end

        translations
      end
    end

    def target_project
      # TODO: other ways to specify project:
      # * parse the email To field
      # * specific project (eg. Setting.mail_handler_target_project)
      target = Project.find_by(identifier: get_keyword(:project))
      raise IncomingEmails::MissingInformation.new("Unable to determine target project") if target.nil?

      target
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
  end
end
