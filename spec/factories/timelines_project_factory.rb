#encoding: utf-8

#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory(:timelines_project, :class => Project) do

    sequence(:name) { |n| "Project #{n}" }
    sequence(:identifier) { |n| "project#{n}" }

    # activate timeline module

    after_create do |project|
      project.enabled_module_names += ["timelines"]
    end

    # add user to project

    after_create do |project|

      role = FactoryGirl.create(:role)
      member = FactoryGirl.build(:member,
                             # we could also just make everybody a member,
                             # since for now we can't pass transient
                             # attributes into factory_girl
                             :user => project.timelines_responsible,
                             :project => project)
      member.roles = [role]
      member.save!
    end

    # generate planning elements

    after_create do |project|

      start_date = rand(18.months).ago
      end_date = start_date

      (5 + rand(20)).times do

        end_date = start_date + (rand(30) + 10).days
        FactoryGirl.create(:timelines_planning_element, :project => project,
                                                    :start_date => start_date,
                                                    :end_date => end_date)
        start_date = end_date

      end
    end

    # create a timeline in that project

    after_create do |project|
      FactoryGirl.create(:timelines_timeline, :project => project)
    end

  end
end

FactoryGirl.define do
  factory(:timelines_uerm_project, :parent => :timelines_project) do
    sequence(:name) { |n| "ÜRM Project #{n}" }

    @project_types = Array.new
    @planning_element_types = Array.new
    @colors = Timelines::Color.ms_project_colors

    # create some project types

    after_create do |project|
      if (@project_types.empty?)

        6.times do
          @project_types << FactoryGirl.create(:timelines_project_type)
        end

      end
    end

    # create some planning_element_types

    after_create do |project|

      20.times do
        planning_element_type = FactoryGirl.create(:timelines_planning_element_type)
        planning_element_type.color = @colors.sample
        planning_element_type.save

        @planning_element_types << planning_element_type
      end

    end


    after_create do |project|

      projects = Array.new

      # create some projects
      #
      50.times do
        projects << FactoryGirl.create(:timelines_project,
                                   :timelines_responsible => project.timelines_responsible)
      end

      projects << FactoryGirl.create(:timelines_project,
                                 :timelines_responsible => project.timelines_responsible)

      projects.each do |r|

        # give every project a project type

        r.timelines_project_type = @project_types.sample
        r.save

        # create a reporting to ürm

        FactoryGirl.create(:timelines_reporting,
                       :project => r,
                       :reporting_to_project => project)

        # give every planning element a planning element type

        r.timelines_planning_elements.each do |pe|
          pe.planning_element_type = @planning_element_types.sample
          pe.save!
        end

        # Add a timeline with history

        FactoryGirl.create(:timelines_timeline_with_history, :project => r)

      end

    end
  end

end
