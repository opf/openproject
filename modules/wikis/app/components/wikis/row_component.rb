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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    alias_method :page, :model

    def title
      render(Primer::Beta::Link.new(href: url_helpers.project_wiki_path(page.wiki.project, page.slug),
                                    font_weight: :bold)) { page.title }
    end

    def project_name
      page.wiki.project.name
    end

    def sub_pages_count
      count = table.sub_pages_counts.fetch(page.id, 0)
      return "-" if count.zero?

      t("wikis.index.sub_pages_count", count:)
    end

    def last_edited
      render(OpPrimer::RelativeTimeComponent.new(datetime: page.updated_at, prefix: nil))
    end
  end
end
