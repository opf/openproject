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

module Saml
  module Providers
    module MetadataChanges
      class RowComponent < ::OpPrimer::BorderBoxRowComponent
        delegate :provider, to: :table

        def attribute
          I18n.t("activerecord.attributes.saml/provider.#{key}")
        end

        def current_value
          current = provider.options_in_database[key]
          return I18n.t(:label_none_parentheses) if current.blank?

          simple_format(h(current.to_s))
        end

        def new_value
          simple_format(h(value.to_s))
        end

        private

        def key = row.first

        def value = row.last
      end
    end
  end
end
