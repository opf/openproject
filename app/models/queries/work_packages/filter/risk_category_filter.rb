# frozen_string_literal: true

class Queries::WorkPackages::Filter::RiskCategoryFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    RiskManagement::RiskCategory.active.order(:position).pluck(:name, :id).map { |name, id| [name, id.to_s] }
  end

  def type
    :list_optional
  end

  def dependency_class
    "::API::V3::Queries::Schemas::IntegerFilterDependencyRepresenter"
  end

  def where
    ids = values.filter_map { |value| Integer(value, exception: false) }
    return "1=0" if ids.empty? && operator == "="

    overlap = "#{WorkPackage.table_name}.risk_category_ids && ARRAY[#{ids.join(',')}]::bigint[]"
    operator == "!" ? "NOT (#{overlap})" : overlap
  end
end
