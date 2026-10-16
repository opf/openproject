# frozen_string_literal: true

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

RSpec.describe API::V3::Labels::LabelRepresenter do
  let(:label) { build_stubbed(:label) }
  let(:representer) { described_class.new(label, current_user: instance_double(User)) }

  describe "generation" do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json("Label".to_json).at_path("_type") }

    describe "label" do
      it { is_expected.to have_json_path("id") }
      it { is_expected.to have_json_path("name") }
      it { is_expected.to have_json_path("createdAt") }
      it { is_expected.to have_json_path("updatedAt") }

      describe "values" do
        it { is_expected.to be_json_eql(label.id.to_json).at_path("id") }
        it { is_expected.to be_json_eql(label.name.to_json).at_path("name") }
      end
    end

    describe "_links" do
      it { is_expected.to have_json_type(Object).at_path("_links") }

      describe "self" do
        it_behaves_like "has a titled link" do
          let(:link) { "self" }
          let(:href) { "/api/v3/labels/#{label.id}" }
          let(:title) { label.name }
        end
      end
    end

    describe "caching" do
      it "is based on the representer's cache_key" do
        allow(OpenProject::Cache)
          .to receive(:fetch)
          .and_call_original

        representer.to_json

        expect(OpenProject::Cache)
          .to have_received(:fetch)
          .with(representer.json_cache_key)
      end

      describe "#json_cache_key" do
        let!(:former_cache_key) { representer.json_cache_key }

        it "includes the name of the representer class" do
          expect(representer.json_cache_key)
            .to include("API", "V3", "Labels", "LabelRepresenter")
        end

        it "changes when the locale changes" do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it "changes when the label is updated" do
          label.updated_at = 20.seconds.from_now

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end
end
