#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++
#
module Query::Highlighting
  extend ActiveSupport::Concern

  module PrependValidHighlightingSubset
    def valid_subset!
      super
      valid_highlighting_subset!
    end
  end

  included do
    prepend PrependValidHighlightingSubset

    QUERY_HIGHLIGHTING_MODES = %i[inline none status type priority].freeze

    serialize :highlighted_attributes, Array

    validates_inclusion_of :highlighting_mode,
                           in: QUERY_HIGHLIGHTING_MODES,
                           allow_nil: true,
                           allow_blank: true

    validate :attributes_highlightable?

    def valid_highlighting_subset!
      self.highlighted_attributes = valid_highlighting_subset
    end

    def available_highlighting_columns
      @available_highlighting_columns ||= available_columns.select(&:highlightable?)
    end

    def highlighted_columns
      columns = available_highlighting_columns.group_by(&:name)

      valid_highlighting_subset
        .map { |name| columns[name.to_sym] }
        .flatten
        .uniq
    end

    def highlighted_attributes
      return [] unless EnterpriseToken.allows_to?(:conditional_highlighting)

      val = super

      if val.present?
        val.map(&:to_sym)
      else
        highlighted_attributes_from_setting
      end
    end

    def highlighting_mode
      return :none unless EnterpriseToken.allows_to?(:conditional_highlighting)

      val = super

      if val.present?
        val.to_sym
      else
        highlighting_mode_from_setting
      end
    end

    def default_highlighting_mode
      QUERY_HIGHLIGHTING_MODES.first
    end

    def attributes_highlightable?
      # Test that chosen attributes intersect with allowed columns
      difference = highlighted_attributes - available_highlighting_columns.map { |col| col.name.to_sym }
      if difference.any?
        errors.add(:highlighted_attributes,
                   I18n.t(:error_attribute_not_highlightable,
                          attributes: difference.map(&:to_s).map(&:capitalize).join(', ')))
      end
    end

    private

    def valid_highlighting_subset
      available_names = available_highlighting_columns.map(&:name)

      highlighted_attributes & available_names
    end

    def highlighted_attributes_from_setting
      settings = Setting.work_package_list_default_highlighted_attributes || []
      values = settings.map(&:to_sym)
      available_names = available_highlighting_columns.map(&:name)
      values & available_names
    end

    def highlighting_mode_from_setting
      value = Setting.work_package_list_default_highlighting_mode.to_sym

      if QUERY_HIGHLIGHTING_MODES.include? value
        value
      else
        default_highlighting_mode
      end
    end
  end
end
