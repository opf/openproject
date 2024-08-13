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

RSpec.describe API::V3::Projects::ProjectPayloadRepresenter, "parsing" do
  include API::V3::Utilities::PathHelper

  let(:object) do
    API::ParserStruct.new available_custom_fields: []
  end
  let(:user) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(object, current_user: user)
  end

  describe "properties" do
    context "for status" do
      let(:hash) do
        {
          "statusExplanation" => { "raw" => "status code explanation" },
          "_links" => {
            "status" => {
              "href" => api_v3_paths.project_status("on_track")
            }
          }
        }
      end

      it "updates code" do
        project = representer.from_hash(hash)
        expect(project.status_code)
          .to eql("on_track")

        expect(project.status_explanation)
          .to eql("status code explanation")
      end

      context "with code not provided" do
        let(:hash) do
          {
            "statusExplanation" => { "raw" => "status code explanation" }
          }
        end

        it "does not set code" do
          project = representer.from_hash(hash)
          expect(project.status_code)
            .to be_nil
        end

        it "updates explanation" do
          project = representer.from_hash(hash)
          expect(project.status_explanation)
            .to eql("status code explanation")
        end
      end

      context "with explanation not provided" do
        let(:hash) do
          {
            "_links" => {
              "status" => {
                "href" => api_v3_paths.project_status("off_track")
              }
            }
          }
        end

        it "does set code" do
          project = representer.from_hash(hash)
          expect(project.status_code)
            .to eql "off_track"
        end

        it "does not set explanation" do
          project = representer.from_hash(hash)
          expect(project.status_explanation)
            .to be_nil
        end
      end

      context "with null for a status" do
        let(:hash) do
          {
            "_links" => {
              "status" => {
                "href" => nil
              }
            }
          }
        end

        it "does set status to nil" do
          project = representer.from_hash(hash)

          expect(project)
            .to have_key(:status_code)
          expect(project)
            .not_to have_key(:status_explanation)

          expect(project.status_code)
            .to be_nil
        end
      end
    end
  end

  describe "_links" do
    context "with a parent link" do
      context "with the href being an url" do
        let(:hash) do
          {
            "_links" => {
              "parent" => {
                "href" => api_v3_paths.project(5)
              }
            }
          }
        end

        it "sets the parent_id to the value" do
          project = representer.from_hash(hash)

          expect(project[:parent_id])
            .to eq "5"
        end
      end

      context "with the href being nil" do
        let(:hash) do
          {
            "_links" => {
              "parent" => {
                "href" => nil
              }
            }
          }
        end

        it "sets the parent_id to nil" do
          project = representer.from_hash(hash)

          expect(project)
            .to have_key(:parent_id)

          expect(project[:parent_id])
            .to be_nil
        end
      end

      context "with the href being the hidden uri" do
        let(:hash) do
          {
            "_links" => {
              "parent" => {
                "href" => API::V3::URN_UNDISCLOSED
              }
            }
          }
        end

        it "omits the parent information" do
          project = representer.from_hash(hash)

          expect(project)
            .not_to have_key(:parent_id)
        end
      end
    end
  end
end
