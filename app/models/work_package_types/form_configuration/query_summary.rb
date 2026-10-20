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

class WorkPackageTypes::FormConfiguration::QuerySummary
  ROW_LABELS = {
    configuration: "label_configuration",
    relation_type: "activerecord.attributes.relation.relation_type",
    columns: "label_columns",
    filters: "label_filter_plural",
    sorting: "js.label_sorting",
    baseline: "js.baseline.toggle_title"
  }.freeze

  def initialize(query)
    @query = query
  end

  def rows
    return [row(:configuration, [t(:unavailable)])] unless @query

    required_rows + { filters: filter_labels, sorting: sort_labels, baseline: baseline_labels }.filter_map do |key, labels|
      row(key, labels) if labels.any?
    end
  end

  private

  def required_rows
    [row(:relation_type, [relation ? relation_label(relation) : I18n.t(:label_none).upcase_first]),
     row(:columns, [column_labels.join(I18n.t("support.array.words_connector"))])]
  end

  def relation
    return @relation if defined?(@relation)

    @relation = @query.filters.find do |filter|
      relation_type?(filter) && filter.operator == "=" &&
        filter.values.any? &&
        (filter.values - [Queries::Filters::TemplatedValue::KEY, Queries::Filters::TemplatedValue::DEPRECATED_KEY]).empty?
    end
  end

  def relation_type?(filter)
    filter.name.to_s == Relation::TYPE_PARENT || Relation::TYPES.key?(filter.name.to_s)
  end

  def filter_labels
    filters = @query.filters.reject { it.equal?(relation) }
    Queries::FilterSummary.new(filters, show_unavailable: true).phrases
  end

  def relation_label(filter)
    Queries::FilterSummary.relation_label(filter.name)
  end

  def column_labels
    return @query.columns.map(&:caption) if @query.has_default_columns?

    available = @query.displayable_columns.index_by { it.name.to_s }
    @query.column_names.map { |name| available[name.to_s]&.caption || I18n.t("queries.filter_summary.unavailable_value") }
  end

  def sort_labels
    criteria = @query.sort_criteria
    return [] if criteria.empty? || criteria == Query::DEFAULT_SORT_CRITERIA

    criteria.map { |name, direction| sort_label(name, direction) }
  end

  def sort_label(name, direction)
    caption = @query.sort_criteria_column(name.to_sym)&.caption || I18n.t("queries.filter_summary.unavailable_value")
    if name.to_s == "manual_sorting"
      caption
    elsif %w[asc desc].include?(direction)
      I18n.t(
        "query.attribute_and_direction",
        attribute: caption,
        direction: I18n.t(direction == "asc" ? :label_ascending : :label_descending)
      )
    else
      I18n.t("queries.filter_summary.unavailable_value")
    end
  end

  def baseline_labels
    return [] unless @query.historic?

    timestamps = @query.timestamps
    return timestamps.map { baseline_text(it).upcase_first } unless timestamps.size == 2

    from, to = timestamps
    if to == Timestamp.now
      [t("baseline.since", time: baseline_text(from))]
    else
      [t("baseline.between", from: baseline_text(from), to: baseline_text(to))]
    end
  end

  def baseline_text(timestamp)
    Timestamp::Humanizer.new(timestamp).text || I18n.t("queries.filter_summary.unavailable_value")
  end

  def row(key, values)
    { label: I18n.t(ROW_LABELS.fetch(key)).upcase_first, values: }
  end

  def t(key, **)
    I18n.t("types.edit.form_configuration.query_summary.#{key}", **)
  end
end
