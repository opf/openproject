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

class BaseMailer < ActionMailer::Base
  helper :application, # for format_text
         :work_packages, # for css classes
         :custom_fields # for show_value
  helper IssuesHelper

  include OpenProject::LocaleHelper

  # Send all delayed mails with the following job
  self.delivery_job = ::MailerJob

  # wrap in a lambda to allow changing at run-time
  default from: Proc.new { Setting.mail_from }

  class << self
    # Activates/deactivates email deliveries during +block+
    def with_deliveries(temporary_state = true, &_block)
      old_state = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = temporary_state
      yield
    ensure
      ActionMailer::Base.perform_deliveries = old_state
    end

    def generate_message_id(object, user)
      # id + timestamp should reduce the odds of a collision
      # as far as we don't send multiple emails for the same object
      journable = (object.is_a? Journal) ? object.journable : object

      timestamp = mail_timestamp(object)
      hash = 'openproject'\
           '.'\
           "#{journable.class.name.demodulize.underscore}"\
           '-'\
           "#{user.id}"\
           '-'\
           "#{journable.id}"\
           '.'\
           "#{timestamp.strftime('%Y%m%d%H%M%S')}"
      host = Setting.mail_from.to_s.gsub(%r{\A.*@}, '')
      host = "#{::Socket.gethostname}.openproject" if host.empty?
      "#{hash}@#{host}"
    end

    def remove_self_notifications(message, author)
      if author.pref && author.pref[:no_self_notified]
        message.to = message.to.reject { |address| address == author.mail } if message.to.present?
      end
    end

    def mail_timestamp(object)
      if object.respond_to? :created_at
        object.send(object.respond_to?(:created_at) ? :created_at : :updated_at)
      else
        object.send(object.respond_to?(:created_on) ? :created_on : :updated_on)
      end
    end

    def host
      if OpenProject::Configuration.rails_relative_url_root.blank?
        Setting.host_name
      else
        Setting.host_name.to_s.gsub(%r{\/.*\z}, '')
      end
    end

    def protocol
      Setting.protocol
    end

    def default_url_options
      options = super.merge host: host, protocol: protocol
      unless OpenProject::Configuration.rails_relative_url_root.blank?
        options[:script_name] = OpenProject::Configuration.rails_relative_url_root
      end

      options
    end
  end

  def mail(headers = {}, &block)
    block ||= method(:default_formats_for_setting)
    super(headers, &block)
  end

  def message_id(object, user)
    headers['Message-ID'] = "<#{self.class.generate_message_id(object, user)}>"
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
end
