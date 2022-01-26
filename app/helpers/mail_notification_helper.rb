#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module MailNotificationHelper
  include ::ColorsHelper

  def logo_tag(**options)
    current_logo = CustomStyle.current.logo unless CustomStyle.current.nil?

    if current_logo.present?
      logo_file = current_logo.local_file
      logo = File.read(logo_file)
      content_type = MIME::Types.type_for(logo_file.path).first.content_type
    else
      logo = File.read(Rails.root.join('app/assets/images/logo_openproject_narrow.svg'))
      content_type = "image/svg+xml"
    end

    email_image_tag(logo, content_type, **options)
  end

  def email_image_tag(image, content_type, **options)
    image_string = image.to_s
    base64_string = Base64.strict_encode64(image_string)

    image_tag "data:#{content_type};base64,#{base64_string}", **options
  end

  def unique_reasons_of_notifications(notifications)
    notifications
      .map(&:reason)
      .uniq
  end

  def notifications_path(id)
    notifications_center_url(['details', id, 'activity'])
  end

  def type_color(type, default_fallback)
    color_id = selected_color(type)
    color_id ? Color.find(color_id).hexcode : default_fallback
  end

  def status_colors(status)
    color_id = selected_color(status)
    Color.find(color_id).color_styles.map { |k, v| "#{k}:#{v};" }.join(' ') if color_id
  end

  def placeholder_table_styles(options = {})
    default_options = {
      style: 'table-layout:fixed;border-collapse:separate;border-spacing:0;font-family:Helvetica;' <<
             (options[:style].present? ? options.delete(:style) : ''),
      cellspacing: "0",
      cellpadding: "0"
    }

    default_options.merge(options).map { |k, v| "#{k}=#{v}" }.join(' ')
  end

  def placeholder_text_styles(**overwrites)
    {
      color: '#878787',
      'line-height': '24px',
      'font-size': '14px',
      'white-space': 'normal',
      overflow: 'hidden',
      'max-width': '100%',
      width: '100%'
    }.merge(overwrites)
     .map { |k, v| "#{k}: #{v}" }
     .join('; ')
  end

  def placeholder_cell(number, vertical:)
    style = if vertical
              "max-width:#{number}; min-width:#{number}; width:#{number}"
            else
              "line-height:#{number}; max-width:0; min-width:0; height:#{number}; width:0; font-size:#{number}"
            end

    content_tag('td', '&nbsp;'.html_safe, style: style)
  end
end
