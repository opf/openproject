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

RSpec.describe API::V3::Queries::Schemas::UserFilterDependencyRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:query) { build_stubbed(:query, project:) }
  let(:filter) { Queries::WorkPackages::Filter::AuthorFilter.create!(context: query) }
  let(:form_embedded) { false }

  let(:instance) do
    described_class.new(filter,
                        operator,
                        form_embedded:)
  end

  subject(:generated) { instance.to_json }

  context "generation" do
    context "properties" do
      describe "values" do
        let(:path) { "values" }
        let(:type) { "[]User" }
        let(:filter_query) do
          [{ type: { operator: "=", values: %w[User Group PlaceholderUser] } },
           { status: { operator: "!", values: ["3"] } },
           { member: { operator: "=", values: [project.id.to_s] } }]
        end
        let(:href) do
          "#{api_v3_paths.principals}?filters=#{CGI.escape(JSON.dump(filter_query))}&pageSize=-1"
        end

        context "for operator 'Queries::Operators::Equals'" do
          let(:operator) { Queries::Operators::Equals }

          it_behaves_like "filter dependency with allowed link"
        end

        context "for operator 'Queries::Operators::NotEquals'" do
          let(:operator) { Queries::Operators::NotEquals }

          it_behaves_like "filter dependency with allowed link"
        end

        context "global" do
          let(:project) { nil }
          let(:filter_query) do
            [{ type: { operator: "=", values: %w[User Group PlaceholderUser] } },
             { status: { operator: "!", values: ["3"] } }]
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
        # fill the cache
        instance.to_json
      end

      it "is cached" do
        expect(instance)
          .not_to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on a different operator" do
        instance.send(:operator=, Queries::Operators::NotEquals)

        expect(instance)
          .to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on a different project" do
        query.project = other_project

        expect(instance)
          .to receive(:to_hash)

        instance.to_json
      end

      it "busts the cache on changes to the locale" do
        expect(instance)
          .to receive(:to_hash)

        I18n.with_locale(:de) do
          instance.to_json
        end
      end

      it "busts the cache on different form_embedded" do
        embedded_instance = described_class.new(filter,
                                                operator,
                                                form_embedded: !form_embedded)
        expect(embedded_instance)
          .to receive(:to_hash)

        embedded_instance.to_json
      end
    end
  end
end
