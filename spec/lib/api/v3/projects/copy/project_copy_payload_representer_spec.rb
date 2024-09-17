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

RSpec.describe API::V3::Projects::Copy::ProjectCopyPayloadRepresenter do
  shared_let(:current_user, reload: false) { build_stubbed(:user) }
  shared_let(:project, reload: false) { build_stubbed(:project) }

  describe "generation" do
    let(:meta) { OpenStruct.new }
    let(:representer) do
      described_class.create(project,
                             meta:,
                             current_user:)
    end

    subject { representer.to_json }

    it "has a _meta property with the copy properties set to true by default but sendNotifications false by default" do
      expect(subject).to have_json_path "_meta"

      Projects::CopyService.copyable_dependencies.each do |dep|
        expect(subject)
          .to be_json_eql(true.to_json)
                .at_path("_meta/copy#{dep[:identifier].camelize}")
      end

      expect(subject)
        .to be_json_eql(false.to_json)
              .at_path("_meta/sendNotifications")
    end

    context "with the meta property containing which associations to copy" do
      let(:meta) { OpenStruct.new only: %[work_packages wiki] }

      it "renders only the selected dependencies as true" do
        Projects::CopyService.copyable_dependencies.each do |dep|
          expect(subject)
            .to be_json_eql(meta.only.include?(dep[:identifier].to_s).to_json)
                  .at_path("_meta/copy#{dep[:identifier].camelize}")
        end
      end
    end

    context "with the meta property to send notifications disabled" do
      let(:meta) { OpenStruct.new send_notifications: false }

      it "renders only the selected dependencies as true" do
        expect(subject)
          .to be_json_eql(false.to_json)
                .at_path("_meta/sendNotifications")
      end
    end
  end

  describe "parsing" do
    let(:representer) do
      described_class.create(OpenStruct.new(available_custom_fields: []),
                             meta: OpenStruct.new,
                             current_user:)
    end

    subject { representer.from_hash parsed_hash }

    context "with meta set" do
      let(:parsed_hash) do
        {
          "name" => "The copied project",
          "_meta" => {
            "copyWorkPackages" => true,
            "copyWiki" => true,
            "sendNotifications" => false
          }
        }
      end

      it "sets all of them to true" do
        expect(subject.name).to eq "The copied project"
        expected_names = Projects::CopyService.copyable_dependencies.pluck(:identifier)
        expect(subject.meta.only).to match_array(expected_names)
        expect(subject.meta.send_notifications).to be false
      end
    end

    context "with one meta copy set to false" do
      let(:parsed_hash) do
        {
          "name" => "The copied project",
          "_meta" => {
            "copyWorkPackages" => false
          }
        }
      end

      it "sets all others to true" do
        expect(subject.name).to eq "The copied project"
        expected_names = Projects::CopyService.copyable_dependencies.pluck(:identifier)
        expect(subject.meta.only).to match_array(expected_names - %w[work_packages])
      end
    end

    context "with a mixture of meta copy set to false" do
      let(:parsed_hash) do
        {
          "name" => "The copied project",
          "_meta" => {
            "copyWorkPackages" => false,
            "copyWiki" => true
          }
        }
      end

      it "still sets all of them to true except work packages" do
        expect(subject.name).to eq "The copied project"
        expected_names = Projects::CopyService.copyable_dependencies.pluck(:identifier)
        expect(subject.meta.only).to match_array(expected_names - %w[work_packages])
      end
    end

    context "with meta unset" do
      let(:parsed_hash) do
        {
          "name" => "The copied project"
        }
      end

      it "does not set meta" do
        expect(subject.name).to eq "The copied project"
        expect(subject.meta).to be_nil
      end
    end
  end
end
