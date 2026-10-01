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

module CustomFields
  class DeleteContract < BaseContract
    class ReferencedInOtherFieldsHtmlError
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::OutputSafetyHelper
      include ActionView::Helpers::TranslationHelper
      include ActionView::Helpers::UrlHelper

      def message(referenced, referencing)
        links = referencing.map do |cf|
          url = admin_settings_project_custom_field_path(cf)
          link_to(cf.name, url)
        end

        t(
          "activerecord.errors.models.custom_field.referenced_in_other_fields_html",
          name: referenced.name,
          links: to_sentence(links),
          count: links.length
        )
      end
    end

    validate :not_referenced

    def validate_model?
      false
    end

    def not_referenced
      referencing = model.class.with_formula_referencing(model)
      return if referencing.empty?

      errors.add(
        :base,
        :referenced_in_other_fields,
        message: ReferencedInOtherFieldsHtmlError.new.message(model, referencing)
      )
    end
  end
end
