# frozen_string_literal: true

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

namespace :bug_found_in_version do
  def bug_found_in_version_option_map(custom_field)
    custom_options = custom_field.custom_options.index_by { |option| option.id.to_s }

    version_names = custom_options.transform_values do |option|
      next nil if option.value == "unreleased/dev"

      option.value.sub(/\.x\z/, ".0")
    end

    [custom_options, version_names]
  end

  def fetch_custom_fields_data
    custom_field = CustomField.find_by(name: "Bug found in version")
    custom_options, option_version_map = bug_found_in_version_option_map(custom_field)
    custom_values = CustomValue
      .where(custom_field:, customized_type: "WorkPackage")
      .where.not(value: nil)

    [custom_options, custom_values, option_version_map]
  end

  def fetch_rows_data(batch, option_version_map)
    rows = batch.pluck(:customized_id, :value)
    work_packages = WorkPackage.where(id: rows.map(&:first)).index_by(&:id)
    version_names = rows.filter_map { |_, value| option_version_map[value] }.uniq
    project_ids = work_packages.values.map(&:project_id).uniq
    versions = Version
      .where(project_id: project_ids, name: version_names)
      .index_by { |version| [version.project_id, version.name] }

    [rows, work_packages, version_names, versions]
  end

  desc "Checks if all conditions are okay to copy Bug found in version to Observed in versions"
  task check: :environment do
    puts " GATHERING DATA "

    custom_options, custom_values, option_version_map = fetch_custom_fields_data

    puts " DATA IS IN "

    puts " OPTION -> VERSION NAME MAPPING "
    option_version_map.each do |option_id, version_name|
      puts "#{custom_options[option_id].value.inspect} -> #{version_name.inspect}"
    end

    rows, work_packages, _version_names, versions = fetch_rows_data(custom_values, option_version_map)

    missing = rows.filter_map do |work_package_id, value|
      version_name = option_version_map[value]
      next if version_name.nil?

      work_package = work_packages.fetch(work_package_id)
      [work_package.project_id, version_name] unless versions.key?([work_package.project_id, version_name])
    end.uniq

    if missing.empty?
      puts " ALL VERSIONS HAVE A MATCH "
    else
      puts " (PROJECT_ID, VERSION NAME) PAIRS WITH NO MATCH: #{missing.inspect} "
    end
  end

  desc "Copy 'Bug found in version' values onto Observed in Versions (does not remove the original value)"
  task copy: :environment do
    puts " GATHERING DATA "

    custom_options, custom_values, option_version_map = fetch_custom_fields_data

    puts " DATA IS IN "

    copied = 0
    skipped_no_version = 0
    skipped_already_observed = 0
    failed = 0

    total = custom_values.count
    custom_values.in_batches(of: 1000).each_with_index do |batch, index|
      puts " HANDLING BATCH #{index + 1} OF #{(total / 1000.0).ceil} "

      rows, work_packages, _version_names, versions = fetch_rows_data(batch, option_version_map)

      existing_observed_in_ids = WorkPackageVersion
        .where(work_package_id: rows.map(&:first), kind: "observed_in")
        .pluck(:work_package_id, :version_id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }

      rows.each do |work_package_id, value|
        work_package = work_packages.fetch(work_package_id)
        option = custom_options[value]
        version_name = option_version_map[value]
        version = version_name && versions[[work_package.project_id, version_name]]

        if version.nil?
          skipped_no_version += 1
          next
        end

        current_ids = existing_observed_in_ids[work_package_id] || []
        if current_ids.include?(version.id)
          skipped_already_observed += 1
          next
        end

        result = WorkPackages::UpdateService
          .new(user: User.system, model: work_package)
          .call(
            observed_in_version_ids: (current_ids + [version.id]).uniq,
            journal_notes: "Copied 'Bug found in version' #{option&.value} to 'Observed in version' #{version.name}."
          )

        if result.success?
          copied += 1
        else
          failed += 1
          puts "WP[#{work_package.id}] - FAILED: #{result.errors.full_messages.to_sentence}"
        end
      end
    end

    puts " SUMMARY "
    puts "Copied: #{copied}"
    puts "Skipped (no matching version): #{skipped_no_version}"
    puts "Skipped (already observed): #{skipped_already_observed}"
    puts "Failed: #{failed}"
  end
end
