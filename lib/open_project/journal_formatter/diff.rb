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

class OpenProject::JournalFormatter::Diff < JournalFormatter::Base
  include OpenProject::StaticRouting::UrlHelpers

  def render(key, values, options = {})
    merge_options = { only_path: true,
                      html: true }.merge(options)

    render_ternary_detail_text(key, values.last, values.first, merge_options)
  end

  private

  def label(key, html: true)
    label = super(key)

    if html
      content_tag("strong", label)
    else
      label
    end
  end

  def render_ternary_detail_text(key, value, old_value, options)
    link = link(key, options)

    label = label(key, html: options[:html])

    if value.blank?
      I18n.t(:text_journal_deleted_with_diff, label:, link:)
    elsif old_value.present?
      I18n.t(:text_journal_changed_with_diff, label:, link:)
    else
      I18n.t(:text_journal_set_with_diff, label:, link:)
    end
  end

  # url_for wants to access the controller method, which we do not have in our Diff class.
  # see: http://stackoverflow.com/questions/3659455/is-there-a-new-syntax-for-url-for-in-rails-3
  def controller
    nil
  end

  def link(key, options)
    url_attr = url_attr(key, options)

    if options[:html]
      link_to(I18n.t(:label_details),
              url_attr,
              target: "_top",
              class: "diff-details")
    else
      url_for url_attr
    end
  end

  def url_attr(key, options)
    default_attributes(options)
    .merge(controller: "/journals",
           action: "diff",
           id: @journal.id,
           field: key.downcase,
           activity_page: options[:activity_page])
  .compact
  end

  def default_attributes(options)
    if options[:only_path]
      { only_path: options[:only_path],
        # setting :script_name is a hack that allows for setting the sub uri.
        # I am not yet sure why url_for normally returns the sub uri but does not within
        # this class.
        script_name: ::OpenProject::Configuration.rails_relative_url_root }
    else
      { only_path: options[:only_path],
        protocol: Setting.protocol,
        host: Setting.host_name }
    end
  end
end
