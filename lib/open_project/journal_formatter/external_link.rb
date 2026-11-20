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

class OpenProject::JournalFormatter::ExternalLink < JournalFormatter::Base
  include SharedMethods

  def render(key, values, options = { html: true })
    if added_or_removed_link?(key, values)
      render_added_or_removed_link(key, values, options)
    else
      super
    end
  end

  private

  def label(key) = attribute_label(key)

  def added_or_removed_link?(key, values)
    key_attribute(key) == "url" && values.include?(nil)
  end

  def render_added_or_removed_link(key, values, options)
    name = link_name(key_link_id(key))
    name = content_tag(:i, name) if options[:html]

    if values.first.nil?
      I18n.t(:text_journal_external_link_added, name:)
    else
      I18n.t(:text_journal_external_link_removed, name:)
    end
  end
end
