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

require "spec_helper"

RSpec.describe API::V3::UserPreferences::NotificationSettingRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  subject(:generated) { representer.to_json }

  let(:project) { build_stubbed(:project) }
  let(:notification_setting) { build_stubbed(:notification_setting, overdue: 3, project:) }

  let(:representer) do
    described_class.create notification_setting,
                           current_user:,
                           embed_links:
  end

  let(:embed_links) { true }

  current_user { build_stubbed(:user) }

  describe "_links" do
    describe "self" do
      # No self link as the representer is rendered as part of the user preferences.
      it_behaves_like "has no link" do
        let(:link) { "self" }
      end
    end

    describe "project" do
      it_behaves_like "has a titled link" do
        let(:link) { "project" }
        let(:href) { api_v3_paths.project(project.id) }
        let(:title) { project.name }
      end
    end
  end

  describe "properties" do
    it "has no _type" do
      expect(generated)
        .not_to have_json_path("_type")
    end

    (NotificationSetting.all_settings - NotificationSetting.date_alert_settings).each do |property|
      it_behaves_like "property", property.to_s.camelize(:lower) do
        let(:value) do
          notification_setting.send property
        end
      end
    end

    context "without enterprise" do
      it "does not have the date alert settings in the resulting json" do
        expect(subject).not_to have_json_path("startDate")
        expect(subject).not_to have_json_path("dueDate")
        expect(subject).not_to have_json_path("overdue")
      end
    end

    context "with enterprise", with_ee: %i[date_alerts] do
      it_behaves_like "property", :startDate do
        let(:value) { "P1D" }
      end
      it_behaves_like "property", :dueDate do
        let(:value) { "P1D" }
      end
      it_behaves_like "property", :overdue do
        let(:value) { "P3D" }
      end
    end
  end

  describe "_embedded" do
    describe "project" do
      it "skips embedding the project" do
        expect(generated)
          .not_to have_json_path("_embedded/project")
      end
    end
  end

  context "when duration settings are all nil" do
    let(:notification_setting) do
      build_stubbed(:notification_setting, project:, start_date: nil, due_date: nil, overdue: nil)
    end

    it "does not represent them in the resulting json" do
      expect(subject).not_to have_json_path("startDate")
      expect(subject).not_to have_json_path("dueDate")
      expect(subject).not_to have_json_path("overdue")
    end
  end
end
