##
# This file contains code that helps extracting seed data from real OP instances.
# It is meant to be copy & pasted into the rails console of the the instance from which you want
# to extract the data from.

# It is very unstable code. However, it should never change the instance it runs in. However, use it with caution.

## Before using it, make sure that all subjects are unique:
# project_identifiers = %w(construction-project bcf-management seed-daten creating-bim-model)
# projects = Project.where(identifier: project_identifiers)
# all_wps = projects.map(&:work_packages).flatten
# all_wps.group_by(&:subject).select { |subject, members| members.size > 1 }.each { |subject, members| puts "#{subject}\t#{members.map(&:id).join("\t")}" }

class Seedifier
  attr_accessor :written_work_packages_ids, :project_identifiers, :projects, :base_date

  def initialize(project_identifiers)
    @project_identifiers = project_identifiers
    @written_work_packages_ids = []
    @projects = Project.where(identifier: @project_identifiers)

    all_work_packages = @projects.map { |project| project.work_packages.to_a }.flatten.sort_by(&:start_date)
    @base_date = all_work_packages.first.start_date.monday
  end

  def run
    @projects.each do |project|
      puts "=== PROJECT: #{project.identifier} ==="
      work_packages = project.work_packages.reject { |work_package| work_package.parent && work_package.parent.project.identifier == project.identifier }.sort_by(&:start_date)
      if work_packages.empty?
        puts "No work packages for project with identifier #{project.identifier}... skipping."
        next
      end

      puts work_packages.map { |work_package| seedify_work_package(work_package, project) }.compact.to_yaml
    end
  end

  def calc_start_offset(work_package)
    if work_package.start_date
      (work_package.start_date - @base_date).to_i
    else
      0
    end
  end

  def calc_duration(work_package)
    if work_package.start_date && work_package.due_date
      (work_package.due_date - work_package.start_date).to_i
    end
  end

  def calc_status(work_package)
    prefix = ''
    if ["Resolved"].include?(work_package.status.name)
      prefix = 'seeders.bim.'
    end
    "#{prefix}default_status_#{calc_low_dash(work_package.status.name.downcase)}"
  end

  def calc_type(work_package)
    prefix = ''
    if ["Issue", "Clash", "Remark", "Request"].include?(work_package.type.name)
      prefix = 'seeders.bim.'
    end
    "#{prefix}default_type_#{calc_low_dash(work_package.type.name.downcase)}"
  end

  def calc_low_dash(name)
    name.tr(" ", "_")
  end

  ##
  # Create a hash that only hold those properties that we would like to copy and paste into a seeder YAML file.
  def seedify_work_package(work_package, project)
    # Don't seed a WP twice. And don't seed WPs of other projects.
    return nil if (@written_work_packages_ids.include?(work_package.id) || work_package.project_id != project.id)

    @written_work_packages_ids << work_package.id

    predecessors = work_package.follows.sort_by(&:start_date).map { |predecessor| { to: predecessor.subject, type: 'follows' } }

    children = work_package.children.sort_by(&:start_date).map { |child| seedify_work_package(child, project) }.compact

    assigned_to = work_package.assigned_to.try(:name)

    duration = calc_duration(work_package)

    seedified = {
      start: calc_start_offset(work_package)
    }

    if work_package.bcf_issue
      seedified[:bcf_issue_uuid] = work_package.bcf_issue.uuid
    else
      seedified[:subject] = work_package.subject
      seedified[:description] = work_package.description
      seedified[:status] = calc_status(work_package)
      seedified[:type] = calc_type(work_package)
      seedified[:estimated_hours] = work_package.estimated_hours if work_package.estimated_hours.present?
      seedified[:children] = children if children.any?
    end

    seedified[:assigned_to] = assigned_to if assigned_to.present?
    seedified[:duration] = duration if duration.present?
    seedified[:parent] = work_package.parent.subject if work_package.parent.present? && (work_package.bcf_issue || work_package.project_id != project.id)
    seedified[:relations] = predecessors if predecessors.any?

    seedified
  end
end

# project_identifiers = ['demo-project']
project_identifiers = %w(construction-project bcf-management seed-daten creating-bim-model)
Seedifier.new(project_identifiers).run