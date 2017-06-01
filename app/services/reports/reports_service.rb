#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Reports::ReportsService
  class_attribute :report_types

  def self.add_report(report)
    self.report_types ||= {}
    self.report_types[report.report_type] = report
  end

  def self.has_report_for?(report_type)
    self.report_types.has_key? report_type
  end

  # automate this? by cycling through each instance of Reports::Report? or is this to automagically?
  # and there is no reason, why plugins shouldn't be able to use this to add their own customized reports...
  add_report Reports::SubprojectReport
  add_report Reports::AuthorReport
  add_report Reports::AssigneeReport
  add_report Reports::ResponsibleReport
  add_report Reports::TypeReport
  add_report Reports::PriorityReport
  add_report Reports::CategoryReport
  add_report Reports::VersionReport

  def initialize(project)
    raise 'You must provide a project to report upon' unless project && project.is_a?(Project)
    @project = project
  end

  def report_for(report_type)
    report_klass = self.class.report_types[report_type]
    report_klass.new(@project) if report_klass
  end
end
