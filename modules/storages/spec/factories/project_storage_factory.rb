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

# Required parameters: project and storage
FactoryBot.define do
  factory :project_storage, class: "::Storages::ProjectStorage" do
    creator factory: :user
    storage factory: :nextcloud_storage
    project factory: :project
    project_folder_id { nil }
    project_folder_mode { "inactive" }

    trait :as_automatically_managed do
      project_folder_mode { "automatic" }
    end

    trait :with_historical_data do
      after(:create) do |project_storage, _evaluator|
        create(:last_project_folder,
               project_storage:,
               origin_folder_id: project_storage.project_folder_id,
               mode: project_storage.project_folder_mode)
      end
    end
  end
end
