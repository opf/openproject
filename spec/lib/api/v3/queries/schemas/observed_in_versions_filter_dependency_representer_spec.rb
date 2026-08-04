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

RSpec.describe API::V3::Queries::Schemas::ObservedInVersionsFilterDependencyRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:query) { build_stubbed(:query, project:) }
  let(:filter) { Queries::WorkPackages::Filter::ObservedInVersionsFilter.create!(context: query) }
  let(:form_embedded) { false }

  let(:instance) do
    described_class.new(filter,
                        operator,
                        form_embedded:)
  end

  subject(:generated) { instance.to_json }

  describe "generation" do
    describe "properties" do
      describe "values" do
        let(:path) { "values" }
        let(:type) { "[]Version" }
        let(:order) { "sortBy=#{CGI.escape(JSON.dump([%i(name asc)]))}&pageSize=-1" }

        context "for operator 'Queries::Operators::All'" do
          let(:operator) { Queries::Operators::All }

          it_behaves_like "filter dependency empty"
        end

        context "for operator 'Queries::Operators::None'" do
          let(:operator) { Queries::Operators::None }

          it_behaves_like "filter dependency empty"
        end

        context "within project" do
          let(:href) do
            "#{api_v3_paths.versions_by_workspace(project.id)}?#{order}"
          end

          context "for operator 'Queries::Operators::Equals'" do
            let(:operator) { Queries::Operators::Equals }

            it_behaves_like "filter dependency with allowed link"
          end

          context "for operator 'Queries::Operators::NotEquals'" do
            let(:operator) { Queries::Operators::NotEquals }

            it_behaves_like "filter dependency with allowed link"
          end
        end

        context "without a project" do
          let(:project) { nil }
          let(:href) do
            "#{api_v3_paths.versions}?#{order}"
          end

          context "for operator 'Queries::Operators::Equals'" do
            let(:operator) { Queries::Operators::Equals }

            it_behaves_like "filter dependency with allowed link"
          end

          context "for operator 'Queries::Operators::NotEquals'" do
            let(:operator) { Queries::Operators::NotEquals }

            it_behaves_like "filter dependency with allowed link"
          end
        end
      end
    end

    describe "caching" do
      let(:operator) { Queries::Operators::Equals }
      let(:other_project) { build_stubbed(:project) }

      before do
        allow(instance).to receive(:to_hash).and_call_original

        # fill the cache
        instance.to_json
      end

      it "is cached" do
        instance.to_json

        expect(instance)
          .to have_received(:to_hash).once
      end

      it "busts the cache on a different operator" do
        instance.send(:operator=, Queries::Operators::NotEquals)

        instance.to_json

        expect(instance)
          .to have_received(:to_hash).twice
      end

      it "busts the cache on a different project" do
        query.project = other_project

        instance.to_json

        expect(instance)
          .to have_received(:to_hash).twice
      end

      it "busts the cache on changes to the locale" do
        I18n.with_locale(:de) do
          instance.to_json
        end

        expect(instance)
          .to have_received(:to_hash).twice
      end

      it "busts the cache on different form_embedded" do
        embedded_instance = described_class.new(filter,
                                                operator,
                                                form_embedded: !form_embedded)
        allow(embedded_instance).to receive(:to_hash).and_call_original

        embedded_instance.to_json

        expect(embedded_instance)
          .to have_received(:to_hash).once
      end
    end
  end
end
