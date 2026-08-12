# frozen_string_literal: true

module WorkPackageTypes::TypeDeactivationErrorMessage
  extend ActiveSupport::Concern

  private

  def type_deactivation_error_messages(types, project_ids:)
    types.map do |type|
      type_deactivation_error_message(type, project_ids:)
    end
  end

  def type_deactivation_error_message(type, project_ids:)
    project_ids = Array(project_ids)
    visible_project_ids = visible_project_ids(project_ids)

    helpers.sanitize(
      I18n.t(:error_can_not_deactivate_type,
             type: type.name,
             work_packages_link: helpers.link_to(
               I18n.t(:label_work_package_plural).downcase,
               affected_work_packages_path(type, project_ids: visible_project_ids),
               target: "_blank",
               rel: "noopener"
             )) + invisible_projects_message(project_ids, visible_project_ids),
      attributes: %w[href target rel]
    )
  end

  # Work packages store the root, so a variant has to be filtered by the family it belongs to.
  def affected_work_packages_path(type, project_ids:)
    filters = [{ n: "type", o: "=", v: [type.root_id] }]
    filters << { n: "project", o: "=", v: project_ids.map(&:to_s) } if project_ids.present?

    work_packages_path query_props: { f: filters }.to_json
  end

  def visible_project_ids(project_ids)
    Project
      .visible
      .where(id: project_ids)
      .pluck(:id)
  end

  def invisible_projects_message(project_ids, visible_project_ids)
    return "" unless project_ids.size > visible_project_ids.size

    " #{I18n.t(:error_can_not_deactivate_type_invisible_projects)}"
  end
end
