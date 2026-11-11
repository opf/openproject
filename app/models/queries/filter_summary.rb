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

# Renders a set of query filters as human-readable text, e.g.
# ["Job title is Developer", "Spoken language is German, English"].
#
#   Queries::FilterSummary.new(query.filters).phrases
#   Queries::FilterSummary.new(placeholder_user.user_filter).to_s
#
# List filters (custom fields, status, …) have their value ids resolved to the
# corresponding objects. Filters that cannot describe themselves are skipped
# by default; show_unavailable: true includes unavailable filter/value markers
# so incomplete stored configuration remains visible without breaking rendering.
class Queries::FilterSummary
  DEFAULT_SEPARATOR = " · "
  RELATIVE_OPERATOR_KEYS = {
    "<t+" => :in_less_than,
    ">t+" => :in_more_than,
    "t+" => :in,
    ">t-" => :less_than_ago,
    "<t-" => :more_than_ago,
    "t-" => :ago
  }.freeze

  def self.relation_label(name)
    return I18n.t("js.relation_labels.children") if name.to_s == Relation::TYPE_PARENT

    I18n.t(Relation::TYPES.fetch(name.to_s).fetch(:sym_name)).upcase_first
  end

  def initialize(filters, show_unavailable: false)
    @filters = Array(filters)
    @show_unavailable = show_unavailable
  end

  delegate :empty?, to: :phrases

  # @return [Array<String>] one phrase per describable filter
  def phrases
    @filters.filter_map { describe(it) }
  end

  # @return [String] all phrases joined for inline display
  def to_s(separator: DEFAULT_SEPARATOR)
    phrases.join(separator)
  end

  private

  def describe(filter)
    if @show_unavailable && !filter.is_a?(::Queries::WorkPackages::Filter::FilterForWpMixin) && !filter.available?
      return unavailable_filter
    end

    return unavailable_filter unless filter.operator_class

    phrase(filter)
  rescue StandardError => e
    Rails.logger.warn("Failed to summarize filter #{filter.name} (#{filter.operator}): #{e.class}: #{e.message}")
    unavailable_filter
  end

  def phrase(filter)
    return translate(filter, :without_values) unless filter.operator_class.requires_value?
    return relative_phrase(filter) if RELATIVE_OPERATOR_KEYS.key?(filter.operator)
    return range_phrase(filter) if filter.operator == "<>d"

    labels = ValueLabels.new(filter, show_unavailable: @show_unavailable).call
    return if labels.empty?

    translate(filter, :with_values, values: labels.join(I18n.t("support.array.words_connector")))
  end

  def translate(filter, key, **)
    I18n.t(
      "queries.filter_summary.#{key}",
      field: field_name(filter),
      operator: filter.operator_class.human_name,
      **
    )
  end

  def field_name(filter)
    if @show_unavailable && (filter.name.to_s == Relation::TYPE_PARENT || Relation::TYPES.key?(filter.name.to_s))
      self.class.relation_label(filter.name)
    else
      filter.human_name
    end
  end

  def unavailable_filter
    I18n.t("queries.filter_summary.unavailable_filter") if @show_unavailable
  end

  def relative_phrase(filter)
    count = Integer(filter.values.first.to_s, exception: false)
    return unavailable_values_phrase(filter) unless filter.values.size == 1 && count && count >= 0

    translate(
      filter,
      "relative.#{RELATIVE_OPERATOR_KEYS.fetch(filter.operator)}",
      duration: I18n.t("datetime.distance_in_words.x_days", count:)
    )
  end

  def unavailable_values_phrase(filter)
    return unless @show_unavailable

    translate(filter, :with_values, values: I18n.t("queries.filter_summary.unavailable_value"))
  end

  def range_phrase(filter)
    return unavailable_values_phrase(filter) unless filter.values.size == 2

    lower, upper = filter.values
    return unavailable_values_phrase(filter) if lower.blank? && upper.blank?
    return open_range_phrase(filter, lower, upper) if lower.blank? || upper.blank?

    closed_range_phrase(filter)
  end

  def closed_range_phrase(filter)
    labels = ValueLabels.new(filter, show_unavailable: @show_unavailable).call
    return unavailable_values_phrase(filter) unless labels.size == 2

    translate(filter, :between, lower: labels.first, upper: labels.last)
  end

  def open_range_phrase(filter, lower, upper)
    copy = filter.dup
    copy.values = [lower.presence || upper]
    labels = ValueLabels.new(copy, show_unavailable: @show_unavailable).call
    return unavailable_values_phrase(filter) if labels.empty?

    translate(filter, lower.blank? ? :until : :from, date: labels.first)
  end
end
