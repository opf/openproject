#encoding: utf-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :project do
    sequence(:name) { |n| "My Project No. #{n}" }
    sequence(:identifier) { |n| "myproject_no_#{n}" }
    enabled_module_names Redmine::AccessControl.available_project_modules

    callback(:before_create) do |project|
      unless ::Type.find(:first, conditions: { is_standard: true })
        project.types << FactoryGirl.build(:type_standard)
      end
    end

    factory :public_project do
      is_public true # Remark: is_public defaults to true
    end

    factory :project_with_types do
      callback(:after_build) do |project|
        project.types << FactoryGirl.build(:type)
      end
      callback(:after_create) do |project|
        project.types.each { |type| type.save! }
      end

      factory :valid_project do
        callback(:after_build) do |project|
          project.types << FactoryGirl.build(:type_with_workflow)
        end
      end
    end

    trait :without_wiki do
      callback(:after_build) do |project|
        project.enabled_module_names = project.enabled_module_names - ['wiki']
      end
    end
  end
end

FactoryGirl.define do
  factory(:timelines_project, :class => Project) do

    sequence(:name) { |n| "Project #{n}" }
    sequence(:identifier) { |n| "project#{n}" }

    # activate timeline module

    callback(:after_create) do |project|
      project.enabled_module_names += ["timelines"]
    end

    # add user to project

    callback(:after_create) do |project|

      role = FactoryGirl.create(:role)
      member = FactoryGirl.build(:member,
                             # we could also just make everybody a member,
                             # since for now we can't pass transient
                             # attributes into factory_girl
                             :user => project.responsible,
                             :project => project)
      member.roles = [role]
      member.save!
    end

    # generate planning elements

    callback(:after_create) do |project|

      start_date = rand(18.months).ago
      due_date = start_date

      (5 + rand(20)).times do

        due_date = start_date + (rand(30) + 10).days
        FactoryGirl.create(:planning_element, :project => project,
                                              :start_date => start_date,
                                              :due_date => due_date)
        start_date = due_date

      end
    end

    # create a timeline in that project

    callback(:after_create) do |project|
      FactoryGirl.create(:timeline, :project => project)
    end

  end
end

FactoryGirl.define do
  factory(:uerm_project, :parent => :project) do
    sequence(:name) { |n| "ÜRM Project #{n}" }

    @project_types = Array.new
    @planning_element_types = Array.new
    @colors = PlanningElementTypeColor.colors

    # create some project types

    callback(:after_create) do |project|
      if (@project_types.empty?)

        6.times do
          @project_types << FactoryGirl.create(:project_type)
        end

      end
    end

    # create some planning_element_types

    callback(:after_create) do |project|

      20.times do
        planning_element_type = FactoryGirl.create(:planning_element_type)
        planning_element_type.color = @colors.sample
        planning_element_type.save

        @planning_element_types << planning_element_type
      end

    end


    callback(:after_create) do |project|

      projects = Array.new

      # create some projects
      #
      50.times do
        projects << FactoryGirl.create(:project,
                                   :responsible => project.responsible)
      end

      projects << FactoryGirl.create(:project,
                                 :responsible => project.responsible)

      projects.each do |r|

        # give every project a project type

        r.project_type = @project_types.sample
        r.save

        # create a reporting to ürm

        FactoryGirl.create(:reporting,
                       :project => r,
                       :reporting_to_project => project)

        # give every planning element a planning element type

        r.planning_elements.each do |pe|
          pe.planning_element_type = @planning_element_types.sample
          pe.save!
        end

        # Add a timeline with history

        FactoryGirl.create(:timeline_with_history, :project => r)

      end

    end
  end

end
