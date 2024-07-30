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

module MailLayoutHelper
  def placeholder_table_styles(options = {})
    default_options = {
      style: "table-layout:fixed;border-collapse:separate;border-spacing:0;font-family:Helvetica;" <<
        (options[:style].present? ? options.delete(:style) : ""),
      cellspacing: "0",
      cellpadding: "0"
    }

    default_options.merge(options).map { |k, v| "#{k}=#{v}" }.join(" ")
  end

  def placeholder_text_styles(**overwrites)
    {
      color: "#878787",
      "line-height": "24px",
      "font-size": "14px",
      "white-space": "normal",
      overflow: "hidden",
      "max-width": "100%",
      width: "100%"
    }.merge(overwrites)
     .map { |k, v| "#{k}: #{v}" }
     .join("; ")
  end

  def action_button(&block)
    render(
      partial: "mailer/mailer_button",
      locals: { block: }
    )
  end

  def placeholder_cell(number, vertical:)
    style = if vertical
              "max-width:#{number}; min-width:#{number}; width:#{number}"
            else
              "line-height:#{number}; max-width:0; min-width:0; height:#{number}; width:0; font-size:#{number}"
            end

    content_tag("td", "&nbsp;".html_safe, style:)
  end

  def user_salutation(user)
    case Setting.emails_salutation
    when :name
      I18n.t(:"mail.salutation", user: user.name)
    else
      I18n.t(:"mail.salutation", user: user.firstname)
    end
  end
end
