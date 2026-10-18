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

class Queries::FilterSummary::ValueLabels
  FINITE_LISTS = %i[list list_all list_optional shared_with_user_list_optional hierarchy].freeze
  ABSOLUTE_DATE_OPERATORS = %w[=d <>d >d <d].freeze
  VISIBILITY_SCOPED_VALUE_OBJECTS = [
    Queries::WorkPackages::Filter::FilterForWpMixin,
    Queries::WorkPackages::Filter::FilterOnVersionsMixin,
    Queries::WorkPackages::Filter::ProjectFilter
  ].freeze

  def initialize(filter, show_unavailable:)
    @filter = filter
    @show_unavailable = show_unavailable
  end

  def call
    return Array(unavailable_value) if @filter.values.compact_blank.empty?
    return object_labels if @filter.ar_object_filter?
    return finite_labels if finite_list?

    @filter.values.filter_map { scalar_label(it) }
  end

  private

  def finite_list?
    FINITE_LISTS.include?(@filter.type) ||
      (@filter.respond_to?(:custom_field) && @filter.custom_field&.field_format == "bool")
  end

  def finite_labels
    options = Array(@filter.allowed_values).to_h { |label, value| [value.to_s, label] }
    @filter.values.filter_map { |value| options[value.to_s] || unavailable_value }
  end

  def scalar_label(value)
    return unavailable_value if value.blank?

    if datetime_value?
      datetime_label(value)
    elsif date_value?
      Redmine::I18n.format_date(Date.iso8601(value))
    elsif %i[integer float].include?(@filter.type)
      numeric_label(value)
    else
      value.to_s
    end
  rescue ArgumentError
    unavailable_value
  end

  def date_value?
    @filter.type == :date && ABSOLUTE_DATE_OPERATORS.include?(@filter.operator)
  end

  def datetime_value?
    @filter.type == :datetime ||
      (@filter.type == :datetime_past && ABSOLUTE_DATE_OPERATORS.include?(@filter.operator))
  end

  def datetime_label(value)
    parsed = DateTime.parse(value)
    if Date._parse(value).key?(:hour)
      Redmine::I18n.format_time(parsed)
    else
      Redmine::I18n.format_date(parsed.to_date)
    end
  end

  def numeric_label(value)
    number = @filter.type == :integer ? Integer(value, 10).to_s : BigDecimal(value).to_s("F")
    ActiveSupport::NumberHelper.number_to_delimited(number)
  end

  def object_labels
    objects = Array(@filter.value_objects).index_by { it.id.to_s }
    @filter.values.filter_map { object_label(it, objects) }
  rescue ActiveRecord::RecordNotFound
    @filter.values.filter_map { object_label(it, {}) }
  end

  def object_label(value, objects)
    symbolic = symbolic_label(value)
    return symbolic if symbolic
    return unavailable_value unless allowed_object_value?(value)

    objects[value.to_s]&.to_s || object_label_for_one(value)
  end

  def symbolic_label(value)
    case value
    when Queries::Filters::TemplatedValue::KEY, Queries::Filters::TemplatedValue::DEPRECATED_KEY
      I18n.t("queries.filter_summary.current_work_package") if @filter.is_a?(Queries::WorkPackages::Filter::FilterForWpMixin)
    when Queries::Filters::MeValue::KEY
      I18n.t(:label_me) if @filter.is_a?(Queries::WorkPackages::Filter::MeValueFilterMixin)
    end
  end

  def allowed_object_value?(value)
    return true unless @show_unavailable && finite_list?
    return true if VISIBILITY_SCOPED_VALUE_OBJECTS.any? { @filter.is_a?(it) }

    @allowed_ids ||= allowed_object_ids
    @allowed_ids.include?(value.to_s)
  end

  def allowed_object_ids
    if @filter.method(:allowed_values).owner == Queries::WorkPackages::Filter::PrincipalBaseFilter
      Queries::WorkPackages::Filter::PrincipalLoader.new(@filter.project)
        .principal_ids_among(@filter.values)
        .to_set(&:to_s)
    else
      @filter.allowed_values.to_set { |_, id| id.to_s }
    end
  end

  def unavailable_value
    I18n.t("queries.filter_summary.unavailable_value") if @show_unavailable
  end

  def object_label_for_one(value)
    copy = @filter.dup
    copy.values = [value]
    object = Array(copy.value_objects).find { it.id.to_s == value.to_s }
    object ? object.to_s : unavailable_value
  rescue ActiveRecord::RecordNotFound
    unavailable_value
  end
end
