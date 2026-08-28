# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class MatrixComponent < ApplicationComponent
      def initialize(project:, query:, counts:, selected_cells:, configuration:)
        super
        @project = project
        @query = query
        @counts = counts
        @explicit_selected_cells = selected_cells
        @configuration = configuration
      end

      def likelihood_options
        @likelihood_options ||= (1..5).to_a.reverse
      end

      def impact_options
        @impact_options ||= (1..5).to_a
      end

      def count(likelihood, impact)
        @counts.fetch([likelihood.to_s, impact.to_s], 0)
      end

      def option_label(option)
        I18n.t("risk_management.risk_log.matrix.levels.#{Assessment::LEVELS.fetch(option - 1)}")
      end

      def cell_path(likelihood, impact)
        selection_path(toggled_cells(likelihood, impact))
      end

      def likelihood_path(likelihood)
        selection_path(toggled_group(row_cells(likelihood)))
      end

      def impact_path(impact)
        selection_path(toggled_group(column_cells(impact)))
      end

      def row_selected?(likelihood)
        group_selected?(row_cells(likelihood))
      end

      def column_selected?(impact)
        group_selected?(column_cells(impact))
      end

      def risk_level(likelihood, impact)
        score = likelihood * impact
        return "success" if score <= 4
        return "attention" if score <= 9
        return "severe" if score <= 16

        "danger"
      end

      def selected?(likelihood, impact)
        selected_cells.include?(cell_key(likelihood, impact))
      end

      def cell_accessible_label(likelihood, impact, selected:)
        label = "#{option_label(likelihood)} (#{likelihood_range(likelihood)}), " \
                "#{option_label(impact)} (#{impact_range(impact)}): " \
                "#{I18n.t('risk_management.risk_log.matrix.risks', count: count(likelihood, impact))}"
        return label unless selected

        "#{label}. #{I18n.t('risk_management.risk_log.matrix.selected')}"
      end

      private

      def selected_cells
        @selected_cells ||= @explicit_selected_cells.map { |likelihood, impact| "#{likelihood}:#{impact}" }
      end

      def toggled_cells(likelihood, impact)
        key = cell_key(likelihood, impact)
        selected_cells.include?(key) ? selected_cells.without(key) : selected_cells + [key]
      end

      def toggled_group(group)
        return selected_cells - group if group_selected?(group)

        (selected_cells + group).uniq
      end

      def group_selected?(group)
        group.all? { |cell| selected_cells.include?(cell) }
      end

      def row_cells(likelihood)
        impact_options.map { |impact| cell_key(likelihood, impact) }
      end

      def column_cells(impact)
        likelihood_options.map { |likelihood| cell_key(likelihood, impact) }
      end

      def selection_path(cells)
        matrix_filter_keys = ["id", "type_id"]
        filters = serialized_filters_without(matrix_filter_keys)
        query_params = helpers.request.query_parameters.except(:filters, :risk_cells, :work_package_id, :tab)

        project_risk_log_path(
          @project,
          query_params.merge(filters: filters.to_json, risk_cells: cells.first(25).join(","))
        )
      end

      def cell_key(likelihood, impact)
        "#{likelihood}:#{impact}"
      end

      def serialize_filter(filter)
        { filter.name.to_s => { "operator" => filter.operator.to_s, "values" => filter.values } }
      end

      def serialized_filters_without(keys)
        @query.filters
          .reject { |filter| keys.include?(filter.name.to_s) }
          .map { |filter| serialize_filter(filter) }
      end

      def likelihood_range(level)
        lower = (level - 1) * 20
        upper = level * 20
        level == 1 ? "0–#{upper}%" : ">#{lower}–#{upper}%"
      end

      def impact_range(level)
        upper = impact_thresholds[level - 1]
        return "> #{formatted_impact(impact_thresholds.last)}" unless upper

        lower = level == 1 ? nil : impact_thresholds[level - 2]
        return "≤ #{formatted_impact(upper)}" unless lower

        "> #{formatted_impact(lower)} – #{formatted_impact(upper)}"
      end

      def impact_thresholds
        @impact_thresholds ||= %i[very_low low medium high].map do |level|
          @configuration.public_send(:"impact_#{level}_max")
        end
      end

      def formatted_impact(value)
        helpers.number_to_currency(value, precision: 0)
      end
    end
  end
end
