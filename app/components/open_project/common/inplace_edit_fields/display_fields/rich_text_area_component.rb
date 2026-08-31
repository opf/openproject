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

module OpenProject
  module Common
    module InplaceEditFields
      module DisplayFields
        class RichTextAreaComponent < DisplayFieldComponent
          include OpenProject::TextFormatting

          attr_reader :model, :attribute, :writable

          def input_specific_call
            render(Primer::BaseComponent.new(tag: :div, **display_field_arguments)) do
              render(Primer::BaseComponent.new(tag: :div,
                                               classes: "op-uc-container op-uc-container_reduced-headings -multiline")) do
                if field_value.present?
                  if truncated
                    name = custom_field? ? custom_field.name : attribute.to_s.humanize
                    render OpenProject::Common::AttributeComponent.new("#{attribute}-truncated-display-field",
                                                                       name,
                                                                       field_value,
                                                                       lines: 3)
                  else
                    format_text(field_value, object: model)
                  end
                else
                  t("placeholders.default")
                end
              end
            end
          end

          private

          def field_value
            model.public_send(attribute)
          end
        end
      end
    end
  end
end
