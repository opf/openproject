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

class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  helper :application, # for format_text
         :work_packages, # for css classes
         :custom_fields, # for show_value
         :mail_layout # for layouting

  include OpenProject::LocaleHelper

  # Send all delayed mails with the following job
  self.delivery_job = ::Mails::MailerJob

  # wrap in a lambda to allow changing at run-time
  default from: Proc.new { Setting.mail_from }

  class << self
    # Activates/deactivates email deliveries during +block+
    def with_deliveries(temporary_state = true, &)
      old_state = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = temporary_state
      yield
    ensure
      ActionMailer::Base.perform_deliveries = old_state
    end

    def host
      if OpenProject::Configuration.rails_relative_url_root.blank?
        Setting.host_name
      else
        Setting.host_name.to_s.gsub(%r{/.*\z}, "")
      end
    end

    def protocol
      Setting.protocol
    end

    def default_url_options
      options = super.merge(host:, protocol:)
      if OpenProject::Configuration.rails_relative_url_root.present?
        options[:script_name] = OpenProject::Configuration.rails_relative_url_root
      end

      options
    end
  end

  # Sets a Message-ID header.
  #
  # While the value is set in here, email gateways such as postmark, unless instructed explicitly will assign
  # their own message id overwriting the value calculated in here.
  #
  # Because of this, the message id and the value affected by it (In-Reply-To) is not relied upon when an email response
  # is handled by OpenProject.
  def message_id(object, user)
    headers["Message-ID"] = "<#{message_id_value(object, user)}>"
  end

  # Sets a References header.
  #
  # The value is used within the MailHandler to find the appropriate objects for update
  # when a mail has been received but should also allow mail clients to mails
  # by the referenced entities. Because of this it might make sense to provide more than one object
  # of reference. E.g. for a message, the message parent can also be provided.
  def references(*objects)
    refs = objects.map do |object|
      if object.is_a?(Journal)
        "<#{references_value(object.journable)}> <#{references_value(object)}>"
      else
        "<#{references_value(object)}>"
      end
    end

    headers["References"] = refs.join(" ")
  end

  # Prepends given fields with 'X-OpenProject-' to save some duplication
  def open_project_headers(hash)
    hash.each { |key, value| headers["X-OpenProject-#{key}"] = value.to_s }
  end

  private

  def default_formats_for_setting(format)
    format.html unless Setting.plain_text_mail?
    format.text
  end

  ##
  # Overwrite mailer method to prevent sending mails to locked users.
  # Usually this would accept a string for the `to:` argument, but
  # we always require an actual user object since fed95796.
  def mail(headers = {}, &block)
    block ||= method(:default_formats_for_setting)
    to = headers[:to]

    if to
      raise ArgumentError, "Recipient needs to be instance of User" unless to.is_a?(User)

      if to.locked?
        Rails.logger.info "Not sending #{action_name} mail to locked user #{to.id} (#{to.login})"
        return
      end
    end

    super(headers.merge(to: to.mail), &block)
  end

  def send_localized_mail(user)
    with_locale_for(user) do
      subject = yield
      mail to: user, subject:
    end
  end

  # Generates a unique value for the Message-ID header.
  # Contains:
  # * an 'op' prefix
  # * an object id part that consists of the object's class name and the id unless that part is provided as a string
  # * the current time
  # * the recipient's id
  #
  # Note that this values, as opposed to the one from #references_value is unique.
  def message_id_value(object, recipient)
    object_reference = case object
                       when String
                         object
                       else
                         "#{object.class.name.demodulize.underscore}-#{object.id}"
                       end
    hash = "op" \
           "." \
           "#{object_reference}" \
           "." \
           "#{Time.current.strftime('%Y%m%d%H%M%S')}" \
           "." \
           "#{recipient.id}"

    "#{hash}@#{header_host_value}"
  end

  # Generates a value for the References header.
  # Contains:
  # * an 'op' prefix
  # * an object id part that consists of the object's class name and the id
  #
  # Note that this values, as opposed to the one from #message_id_value is not unique.
  # It in fact is aimed not not so that similar messages (i.e. those belonging to the same
  # work package and journal) end up being grouped together.
  def references_value(object)
    hash = "op" \
           "." \
           "#{object.class.name.demodulize.underscore}-#{object.id}"

    "#{hash}@#{header_host_value}"
  end

  def header_host_value
    host = Setting.mail_from.to_s.gsub(%r{\A.*@}, "")
    host = "#{::Socket.gethostname}.openproject" if host.empty?
    host
  end
end
