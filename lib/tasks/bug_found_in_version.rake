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

  def fetch_rows_data(batch, option_version_map) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    rows = batch.pluck(:customized_id, :value)
    work_packages = WorkPackage.where(id: rows.map(&:first)).includes(:project).index_by(&:id)
    rows, orphaned = rows.partition { |work_package_id, _| work_packages[work_package_id]&.project }

    version_names = rows.filter_map { |_, value| option_version_map[value] }.uniq
    version_names_set = version_names.to_set
    projects = rows.map { |work_package_id, _| work_packages.fetch(work_package_id).project }.uniq

    versions = {}
    ambiguous = Set.new

    projects.each do |project|
      project.assignable_versions(only_open: false)
        .select { |version| version_names_set.include?(version.name) }
        .group_by(&:name)
        .each do |name, matches|
          if matches.one?
            versions[[project.id, name]] = matches.first
          else
            ambiguous << [project.id, name]
          end
        end
    end

    [rows, work_packages, version_names, versions, orphaned, ambiguous]
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

    rows, work_packages, _version_names, versions, orphaned, ambiguous =
      fetch_rows_data(custom_values, option_version_map)

    existing_observed_in_ids = WorkPackageVersion
      .where(work_package_id: rows.map(&:first), kind: "observed_in")
      .pluck(:work_package_id, :version_id)
      .group_by(&:first)
      .transform_values { |pairs| pairs.map(&:last) }

    missing = []
    ambiguous_pairs = []
    skipped_unmapped = 0
    to_create = 0

    rows.each do |work_package_id, value|
      version_name = option_version_map[value]

      if version_name.nil?
        skipped_unmapped += 1
        next
      end

      work_package = work_packages.fetch(work_package_id)
      version = versions[[work_package.project_id, version_name]]

      if version.nil?
        pair = [work_package.project_id, version_name]
        ambiguous.include?(pair) ? ambiguous_pairs << pair : missing << pair
        next
      end

      to_create += 1 unless (existing_observed_in_ids[work_package_id] || []).include?(version.id)
    end

    missing.uniq!
    ambiguous_pairs.uniq!

    if missing.empty?
      puts " ALL MAPPED VERSIONS HAVE A MATCH "
    else
      puts " (PROJECT_ID, VERSION NAME) PAIRS WITH NO MATCH: #{missing.inspect} "
    end

    unless ambiguous_pairs.empty?
      puts " (PROJECT_ID, VERSION NAME) PAIRS AMBIGUOUS - MULTIPLE VERSIONS SHARE THIS NAME, " \
           "DEDUPE INSTEAD OF CREATING: #{ambiguous_pairs.inspect} "
    end

    puts " #{skipped_unmapped} VALUES HAVE NO VERSION MAPPING (e.g. 'unreleased/dev') "
    puts " #{orphaned.size} VALUES SKIPPED (WORK PACKAGE DELETED OR HAS NO PROJECT) "
    puts " #{to_create} RECORDS TO BE CREATED "
  end

  desc "Copy 'Bug found in version' values onto Observed in Versions (does not remove the original value)"
  task copy: %i[environment check] do
    puts " GATHERING DATA "

    _custom_options, custom_values, option_version_map = fetch_custom_fields_data

    puts " DATA IS IN "

    copied = 0
    skipped_no_version = 0
    skipped_ambiguous = 0
    skipped_already_observed = 0
    skipped_orphaned = 0
    failed = 0

    total = custom_values.count
    custom_values.in_batches(of: 1000).each_with_index do |batch, index|
      puts " HANDLING BATCH #{index + 1} OF #{(total / 1000.0).ceil} "

      rows, work_packages, _version_names, versions, orphaned, ambiguous = fetch_rows_data(batch, option_version_map)
      skipped_orphaned += orphaned.size

      existing_observed_in_ids = WorkPackageVersion
        .where(work_package_id: rows.map(&:first), kind: "observed_in")
        .pluck(:work_package_id, :version_id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }

      rows.each do |work_package_id, value|
        work_package = work_packages.fetch(work_package_id)
        version_name = option_version_map[value]
        version = version_name && versions[[work_package.project_id, version_name]]

        if version.nil?
          if version_name && ambiguous.include?([work_package.project_id, version_name])
            skipped_ambiguous += 1
          else
            skipped_no_version += 1
          end
          next
        end

        if (existing_observed_in_ids[work_package_id] || []).include?(version.id)
          skipped_already_observed += 1
          next
        end

        begin
          ActiveRecord::Base.transaction do
            WorkPackageVersion.create!(work_package_id:, version_id: version.id, kind: "observed_in")
            result = Journals::CreateService.new(work_package, User.system).call
            raise "failed to create journal" if result.result.nil?
          end

          copied += 1
        rescue StandardError => e
          failed += 1
          puts "WP[#{work_package_id}] - FAILED: #{e.message}"
        end
      end
    end

    puts " SUMMARY "
    puts "Copied: #{copied}"
    puts "Skipped (no matching version): #{skipped_no_version}"
    puts "Skipped (ambiguous - multiple versions share the name): #{skipped_ambiguous}"
    puts "Skipped (already observed): #{skipped_already_observed}"
    puts "Skipped (orphaned - work package deleted or has no project): #{skipped_orphaned}"
    puts "Failed: #{failed}"
  end
end
