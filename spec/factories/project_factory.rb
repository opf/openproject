# encoding: utf-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
    transient do
      no_types false
      disable_modules []
    end

    sequence(:name) { |n| "My Project No. #{n}" }
    sequence(:identifier) { |n| "myproject_no_#{n}" }
    created_on { Time.now }
    updated_on { Time.now }
    enabled_module_names Redmine::AccessControl.available_project_modules

    callback(:after_build) do |project, evaluator|
      disabled_modules = Array(evaluator.disable_modules)
      project.enabled_module_names = project.enabled_module_names - disabled_modules
    end

    callback(:before_create) do |project, evaluator|
      unless evaluator.no_types ||
             Type.where(is_standard: true).count > 0
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
        project.types.each(&:save!)
      end

      factory :valid_project do
        callback(:after_build) do |project|
          project.types << FactoryGirl.build(:type_with_workflow)
        end
      end
    end
  end
end
