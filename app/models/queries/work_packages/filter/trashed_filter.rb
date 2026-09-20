# frozen_string_literal: true

class Queries::WorkPackages::Filter::TrashedFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::Filters::Shared::BooleanFilter

  def available?
    WorkPackages::TrashFeature.enabled? &&
      if project
        User.current.allowed_in_project?(:view_work_packages_in_trash, project)
      else
        User.current.allowed_in_any_project?(:view_work_packages_in_trash)
      end
  end

  def dependency_class
    "::API::V3::Queries::Schemas::BooleanFilterDependencyRepresenter"
  end

  def where
    if filtering_for_true?
      "#{WorkPackage.table_name}.deleted_at IS NOT NULL"
    else
      "#{WorkPackage.table_name}.deleted_at IS NULL"
    end
  end

  def human_name
    I18n.t("query_fields.trashed")
  end
end
