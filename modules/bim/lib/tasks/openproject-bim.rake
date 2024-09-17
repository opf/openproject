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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

##
# This file contains code that helps extracting seed data from real OP instances.
# It is meant to be copy & pasted into the rails console of the the instance from which you want
# to extract the data from.

# It is very unstable code. However, it should never change the instance it runs in. However, use it with caution.

## Before using it, make sure:
# that the default language is :en
# that the seeded status, types, and priority names have never been changed
# that all subjects are unique:
#   project_identifiers = %w(construction-project bcf-management seed-daten creating-bim-model)
#   projects = Project.where(identifier: project_identifiers)
#   all_wps = projects.map(&:work_packages).flatten
#   all_wps.group_by(&:subject).select { |subject, members| members.size > 1 }.each { |subject, members| puts "#{subject}\t#{members.map(&:id).join("\t")}" }
class Seedifier
  attr_accessor :written_work_packages_ids, :project_identifiers, :projects, :base_date

  def initialize(project_identifiers)
    @project_identifiers = project_identifiers
    @written_work_packages_ids = []
    @projects = Project.where(identifier: @project_identifiers)

    raise "Warning: this class and the bim:seedify task have not been maintained when " \
          "work package 36933 was implemented as it was out-of-scope. It will probably " \
          "fail to produce the expected output."

    all_work_packages = @projects.map { |project| project.work_packages.to_a }.flatten.sort_by(&:start_date)
    @base_date = all_work_packages.first.start_date.monday
  end

  def run
    @projects.each do |project|
      puts "=== PROJECT: #{project.identifier} ==="
      work_packages = project.work_packages.reject do |work_package|
        work_package.parent && work_package.parent.project.identifier == project.identifier
      end.sort_by(&:start_date)
      if work_packages.empty?
        puts "No work packages for project with identifier #{project.identifier}... skipping."
        next
      end

      puts work_packages.filter_map { |work_package| seedify_work_package(work_package, project) }.to_yaml
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
    prefix = ""
    if ["Resolved"].include?(work_package.status.name)
      prefix = "bim."
    end
    "#{prefix}default_status_#{calc_low_dash(work_package.status.name.downcase)}"
  end

  def calc_type(work_package)
    prefix = ""
    if ["Issue", "Clash", "Remark", "Request"].include?(work_package.type.name)
      prefix = "bim."
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
    return nil if @written_work_packages_ids.include?(work_package.id) || work_package.project_id != project.id

    @written_work_packages_ids << work_package.id

    predecessors = work_package.follows.sort_by(&:start_date).map { |predecessor| { to: predecessor.subject, type: "follows" } }

    children = work_package.children.sort_by(&:start_date).filter_map { |child| seedify_work_package(child, project) }

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
    if work_package.parent.present? && (work_package.bcf_issue || work_package.project_id != project.id)
      seedified[:parent] =
        work_package.parent.subject
    end
    seedified[:relations] = predecessors if predecessors.any?

    seedified
  end
end

namespace :bim do
  task seedify: :environment do
    # project_identifiers = ['demo-project']
    project_identifiers = %w(construction-project bcf-management seed-daten creating-bim-model)
    Seedifier.new(project_identifiers).run
  end
end
