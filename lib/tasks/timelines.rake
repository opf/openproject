# encoding: utf-8
#
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

namespace :timelines do
  namespace :clear do
    desc 'Delete all timelines-related models'
    task all: [:environment,
               :colors, :project_types, :planning_element_types,
               :reported_project_status, :planning_element_status,
               :available_project_status]

    task colors: :environment do
      Color.delete_all
    end

    task project_types: :environment do
      ProjectType.delete_all
    end

    task planning_element_types: :environment do
      PlanningElementType.delete_all
    end

    task reported_project_status: :environment do
      ReportedProjectStatus.delete_all
    end

    task planning_element_status: :environment do
      PlanningElementStatus.delete_all
    end

    task available_project_status: :environment do
      AvailableProjectStatus.delete_all
    end
  end

  namespace :load do
    desc 'Load some pre-defined test data'
    task all: [:environment,
               :colors, :project_types, :planning_element_types,
               :reported_project_status, :planning_element_status,
               :available_project_status]

    task colors: :environment do
      Color.colors.map(&:save!)
    end

    task project_types: :environment do
      %w{ÜRM QAM PM}.each do |name|
        ProjectType.create!(name: name, allows_association: false)
      end
      %w{Anforderung Release Test Umgebung}.each do |name|
        ProjectType.create!(name: name, allows_association: true)
      end
    end

    task planning_element_types: :environment do
      {
        'Release' => [
          { name: 'Entwicklung',   color: 'pjBlue', is_default: true },
          { name: 'BzA',           color: 'pjFuchsia', is_milestone: true },
          { name: 'Testing',       color: 'pjYellow' },
          { name: 'Preproduction', color: 'pjMaroon' },
          { name: 'Rollout',       color: 'pjLime', in_aggregation: false },
          { name: 'PNPA',          color: 'pjOlive', in_aggregation: false }
        ],

        'Test' => [
          { name: 'Feasibility Study', color: 'pjBlue', is_default: true },
          { name: 'Impact Analysis',   color: 'pjYellow' },
          { name: 'Testplanung',       color: 'pjMaroon' },
          { name: 'Testspezifikation', color: 'pjWhite' },
          { name: 'Testdurchführung',  color: 'pjNavy' },
          { name: 'Deployment ATU1',   color: 'pjPurple', is_milestone: true },
          { name: 'Deployment ATU2',   color: 'pjTeal', is_milestone: true },
          { name: 'Backup',            color: 'pjAqua' },
          { name: 'Reporting',         color: 'pjSilver' },
        ],

        'Anforderung' => [
          { name: 'FS', color: 'pjBlue' },
          { name: 'DD', color: 'pjYellow' },
          { name: 'RE', color: 'pjMaroon' },
          { name: 'LA', color: 'pjLime' }
        ],

        'Umgebung' => [
        ]
      }.each do |project_type_name, planning_element_types|
        project_type = ProjectType.find_by(name: project_type_name)
        raise "Could not find ProjectType named #{project_type_name}" if project_type.blank?

        planning_element_types.each do |planning_element_type|
          planning_element_type[:color] = Color.find_by(name: planning_element_type[:color])
          PlanningElementType.create!(planning_element_type.merge(project_type_id: project_type.id))
        end
      end

      [
        { name: 'Phase', color: 'pjGray' },
        { name: 'Milestone', color: 'pjGray', is_milestone: true }
      ].each do |planning_element_type|
        planning_element_type[:color] = Color.find_by(name: planning_element_type[:color])
        PlanningElementType.create!(planning_element_type)
      end
    end

    task reported_project_status: :environment do
      ['Alle Daten vorhanden', 'Unvollständig', 'Offen', 'Verzug'].each do |name|
        ReportedProjectStatus.create!(name: name)
      end
    end

    task planning_element_status: :environment do
      ['Keine Planung', 'Vorläufige Planung', 'Im Plan', 'Verzögerung', 'Eskalation'].each do |name|
        ReportedProjectStatus.create!(name: name)
      end
    end

    task available_project_status: :environment do
      ReportedProjectStatus.all.each do |status|
        ProjectType.all.each do |type|
          s = AvailableProjectStatus.new
          s.reported_project_status = status
          s.project_type = type
          s.save!
        end
      end
    end
  end
end
