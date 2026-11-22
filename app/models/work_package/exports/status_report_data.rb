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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackage::Exports::StatusReportData
  TEMPLATE_ID = "status_report"

  attr_reader :work_package

  def self.enabled_for?(work_package)
    variant = work_package.type_variant
    return false if variant.nil?

    variant.pdf_export_templates.find(TEMPLATE_ID).enabled
  end

  def initialize(work_package, current_user:)
    @work_package = work_package
    @current_user = current_user
  end

  def form_configuration
    @form_configuration ||= WorkPackage::Exports::FormConfiguration.new(work_package)
  end

  def query_groups
    form_configuration.groups.grep(WorkPackage::Exports::FormConfiguration::QueryGroup)
  end

  def related_work_packages(group)
    group.work_packages.select { |candidate| related_work_package_ids.include?(candidate.id) }
  end

  private

  def related_work_package_ids
    @related_work_package_ids ||= work_package.relations
                                              .visible(@current_user)
                                              .pluck(:from_id, :to_id)
                                              .flatten
                                              .to_set
                                              .delete(work_package.id)
  end
end
