#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class OpenProject::JournalFormatter::Attachment < ::JournalFormatter::Base
  # unloadable

  include ApplicationHelper
  include OpenProject::StaticRouting::UrlHelpers

  def self.default_url_options
    { only_path: true }
  end

  def render(key, values, options = { no_html: false })
    label, old_value, value = format_details(key.to_s.sub('attachments_', ''), values)

    unless options[:no_html]
      label, old_value, value = *format_html_details(label, old_value, value)

      value = format_html_attachment_detail(key.to_s.sub('attachments_', ''), value)
    end

    render_binary_detail_text(label, value, old_value)
  end

  private

  def label(_key)
    Attachment.model_name.human
  end

  # we need to tell the url_helper that there is not controller to get url_options
  # so that we can later call link_to and url_for within format_html_attachment_detail > link_to_attachment
  def controller
    nil
  end

  def format_html_attachment_detail(key, value)
    if !value.blank? && a = Attachment.find_by_id(key.to_i)
      link_to_attachment(a, only_path: false)
    else
      value if value.present?
    end
  end
end
