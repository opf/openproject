# frozen_string_literal: true

class Queries::WorkPackages::Filter::RiskLikelihoodFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def type
    :float
  end
end
