# frozen_string_literal: true

class Queries::WorkPackages::Filter::RiskOwnerFilter <
  Queries::WorkPackages::Filter::PrincipalBaseFilter
  def type
    :list_optional
  end

  def self.key
    :risk_owner_id
  end

  def dependency_class
    "::API::V3::Queries::Schemas::ProjectMembersFilterDependencyRepresenter"
  end

  private

  def autocomplete_principal_types
    ["User"]
  end
end
