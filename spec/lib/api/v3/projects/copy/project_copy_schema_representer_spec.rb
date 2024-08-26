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

RSpec.describe API::V3::Projects::Copy::ProjectCopySchemaRepresenter do
  include API::V3::Utilities::PathHelper

  shared_let(:current_user, reload: false) { build_stubbed(:user) }
  shared_let(:source_project, reload: false) { build_stubbed(:project) }
  shared_let(:contract, reload: false) { Projects::CreateContract.new(source_project, current_user) }

  shared_let(:representer, reload: false) do
    described_class.create(contract,
                           self_link: "/a/self/link",
                           form_embedded: true,
                           current_user:)
  end

  shared_let(:subject, reload: false) { representer.to_json }

  describe "_type" do
    it "is indicated as Schema" do
      expect(subject).to be_json_eql("Schema".to_json).at_path("_type")
    end
  end

  describe "send_notifications" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "sendNotifications" }
      let(:type) { "Boolean" }
      let(:name) { I18n.t(:label_project_copy_notifications) }
      let(:required) { false }
      let(:has_default) { true }
      let(:writable) { true }
      let(:location) { "_meta" }
    end
  end

  describe "copy properties" do
    Projects::CopyService.copyable_dependencies.each do |dep|
      it_behaves_like "has basic schema properties" do
        let(:path) { "copy#{dep[:identifier].camelize}" }
        let(:type) { "Boolean" }
        let(:name) { dep[:name_source].call }
        let(:required) { false }
        let(:has_default) { true }
        let(:writable) { true }
        let(:location) { "_meta" }
        let(:description) { "No objects of this type" }
      end
    end
  end
end
