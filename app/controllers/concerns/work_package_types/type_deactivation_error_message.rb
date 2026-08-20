# frozen_string_literal: true

module WorkPackageTypes::TypeDeactivationErrorMessage
  extend ActiveSupport::Concern

  private

  def type_deactivation_error_messages(variants, project_ids:)
    projects = visible_projects(project_ids)

    messages = Array(variants).flat_map do |variant|
      projects.map { |project| type_deactivation_error_message(variant, project:) }
    end

    messages << I18n.t(:error_can_not_deactivate_type_invisible_projects) if hidden_any?(project_ids, projects)

    messages
  end

  def type_deactivation_error_message(variant, project:)
    helpers.sanitize(
      I18n.t(:error_can_not_remove_type_from_project,
             name: variant.composite_name,
             project: project.name,
             work_packages_link: helpers.link_to(
               I18n.t(:label_work_package_plural).downcase,
               affected_work_packages_path(variant.type, project_ids: [project.id]),
               target: "_blank",
               rel: "noopener"
             )),
      attributes: %w[href target rel]
    )
  end

  def affected_work_packages_path(type, project_ids:)
    filters = [{ n: "type", o: "=", v: [type.id] }]
    filters << { n: "project", o: "=", v: project_ids.map(&:to_s) } if project_ids.present?

    work_packages_path query_props: { f: filters }.to_json
  end

  def visible_projects(project_ids)
    Project.visible.where(id: Array(project_ids))
  end

  def hidden_any?(project_ids, visible)
    Array(project_ids).size > visible.size
  end
end
