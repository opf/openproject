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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  class AttributesGroupComponent < ::Primer::Component
    SCHEME_DEFAULT = :default
    SCHEME_OPTIONS = [SCHEME_DEFAULT, :tabular].freeze
    LABEL_COLOR_DEFAULT = :default
    LABEL_COLOR_OPTIONS = [LABEL_COLOR_DEFAULT, :muted].freeze

    renders_one :header, Header
    renders_many :attributes, AttributeKeyValue

    attr_reader :system_arguments

    # @param scheme [Symbol] <%= one_of(OpPrimer::AttributesGroupComponent::SCHEME_OPTIONS) %>
    # @param label_color [Symbol] <%= one_of(OpPrimer::AttributesGroupComponent::LABEL_COLOR_OPTIONS) %>
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(scheme: SCHEME_DEFAULT, label_color: LABEL_COLOR_DEFAULT, **system_arguments)
      super()
      @system_arguments = system_arguments

      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "AttributesGroup",
        "AttributesGroup--tabular" => fetch_or_fallback(SCHEME_OPTIONS, scheme, SCHEME_DEFAULT) == :tabular,
        "AttributesGroup--mutedLabels" => fetch_or_fallback(LABEL_COLOR_OPTIONS, label_color, LABEL_COLOR_DEFAULT) == :muted
      )
    end
  end
end
