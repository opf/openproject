# frozen_string_literal: true

class Queries::WorkPackages::Filter::RiskResponseFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  RESPONSES = %w[mitigate accept avoid transfer].freeze

  def allowed_values
    RESPONSES.map { |value| [I18n.t("risk_management.risk_responses.#{value}"), value] }
  end

  def type
    :list_optional
  end

  def dependency_class
    "::API::V3::Queries::Schemas::TextFilterDependencyRepresenter"
  end
end
