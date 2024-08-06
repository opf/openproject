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

RSpec.describe API::V3::Priorities::PriorityRepresenter do
  let(:priority) { build_stubbed(:priority) }
  let(:representer) { described_class.new(priority, current_user: double("current_user")) }

  include API::V3::Utilities::PathHelper

  context "generation" do
    subject { representer.to_json }

    it "indicates its type" do
      expect(subject).to include_json("Priority".to_json).at_path("_type")
    end

    describe "links" do
      it { is_expected.to have_json_type(Object).at_path("_links") }

      it "links to self" do
        path = api_v3_paths.priority(priority.id)

        expect(subject).to be_json_eql(path.to_json).at_path("_links/self/href")
      end

      it "displays its name as title in self" do
        expect(subject).to be_json_eql(priority.name.to_json).at_path("_links/self/title")
      end
    end

    describe "priority" do
      it "has an id" do
        expect(subject).to be_json_eql(priority.id.to_json).at_path("id")
      end

      it "has a name" do
        expect(subject).to be_json_eql(priority.name.to_json).at_path("name")
      end

      it "has a position" do
        expect(subject).to be_json_eql(priority.position.to_json).at_path("position")
      end

      it "has a default flag" do
        expect(subject).to be_json_eql(priority.is_default.to_json).at_path("isDefault")
      end

      it "has an active flag" do
        expect(subject).to be_json_eql(priority.active.to_json).at_path("isActive")
      end
    end

    describe "caching" do
      it "is based on the representer's cache_key" do
        expect(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json
      end

      describe "#json_cache_key" do
        let!(:former_cache_key) { representer.json_cache_key }

        it "includes the name of the representer class" do
          expect(representer.json_cache_key)
            .to include("API", "V3", "Priorities", "PriorityRepresenter")
        end

        it "changes when the locale changes" do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it "changes when the priority is updated" do
          priority.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end
end
