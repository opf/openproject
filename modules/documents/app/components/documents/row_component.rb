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
#

module Documents
  class RowComponent < OpPrimer::BorderBoxRowComponent
    include Redmine::I18n

    alias_method :document, :model

    def row_css_id
      ActionView::RecordIdentifier.dom_id(document)
    end

    def name
      safe_join(
        [
          render(
            Primer::Beta::Link.new(
              href: document_path(document),
              font_weight: :bold,
              mr: 1,
              data: { test_selector: "document-name" }
            )
          ) { document.title },
          classic_label
        ].compact
      )
    end

    def type
      return if document.type.blank?

      render(
        Primer::Beta::Truncate.new(font_weight: :normal, color: :subtle, data: { test_selector: "document-type" })
      ) { document.type.name }
    end

    def updated_at
      render(Primer::Beta::Text.new(font_weight: :light, color: :subtle)) { updated_at_time }
    end

    private

    def classic_label
      return unless document.classic?

      render(Primer::Beta::Label.new(scheme: :default, test_selector: "label-legacy")) do
        I18n.t("documents.index_page.label_legacy")
      end
    end

    def updated_at_time
      OpPrimer::RelativeTimeComponent.new(
        datetime: in_user_zone(document.updated_at),
        month: :long
      ).render_in(view_context)
    end
  end
end
