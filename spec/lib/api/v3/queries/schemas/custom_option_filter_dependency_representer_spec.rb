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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe API::V3::Queries::Schemas::CustomOptionFilterDependencyRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:query) { build_stubbed(:query, project:) }
  let(:custom_field) do
    cf = build_stubbed(:list_wp_custom_field)

    allow(cf)
      .to receive(:custom_options)
      .and_return([build_stubbed(:custom_option),
                   build_stubbed(:custom_option)])
    cf
  end
  let(:filter) do
    Queries::WorkPackages::Filter::CustomFieldFilter.from_custom_field! custom_field:,
                                                                        context: query
  end
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
        let(:type) { "[]CustomOption" }
        let(:hrefs) do
          custom_field.custom_options.map do |value|
            api_v3_paths.custom_option(value.id)
          end
        end

        context "for operator 'Queries::Operators::Equals'" do
          let(:operator) { Queries::Operators::Equals }

          it_behaves_like "filter dependency with allowed value link collection"
        end

        context "for operator 'Queries::Operators::NotEquals'" do
          let(:operator) { Queries::Operators::NotEquals }

          it_behaves_like "filter dependency with allowed value link collection"
        end

        context "for operator 'Queries::Operators::All'" do
          let(:operator) { Queries::Operators::All }

          it_behaves_like "filter dependency empty"
        end

        context "for operator 'Queries::Operators::None'" do
          let(:operator) { Queries::Operators::None }

          it_behaves_like "filter dependency empty"
        end
      end
    end

    describe "with project-specific values" do
      let(:type) { create(:type) }
      let(:project) { create(:project, types: [type]) }
      let(:other_project) { create(:project, types: [type]) }
      let(:query) { build_stubbed(:query, project: nil) }
      let(:custom_field) do
        create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B])
      end
      let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
      let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
      let(:member) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
      let(:other_member) { create(:user, member_with_permissions: { other_project => %i[view_work_packages] }) }
      let(:operator) { Queries::Operators::Equals }

      before do
        create(:project_specific_value_restriction, project:, custom_option: option_a)
        create(:project_specific_value_restriction, project: other_project, custom_option: option_b)
      end

      it "only allows the options visible to the user, even when another user's schema is cached" do
        json = User.execute_as(member) do
          API::V3::Queries::Schemas::FilterDependencyRepresenterFactory.create(filter, operator, form_embedded: true).to_json
        end
        other_json = User.execute_as(other_member) do
          API::V3::Queries::Schemas::FilterDependencyRepresenterFactory.create(filter, operator, form_embedded: true).to_json
        end

        expect(JSON.parse(json).dig("values", "_links", "allowedValues").pluck("href"))
          .to eq([api_v3_paths.custom_option(option_a.id)])
        expect(JSON.parse(other_json).dig("values", "_links", "allowedValues").pluck("href"))
          .to eq([api_v3_paths.custom_option(option_b.id)])
      end
    end

    describe "caching" do
      let(:operator) { Queries::Operators::Equals }

      before do
        # fill the cache
        instance.extend(API::V3::Queries::Schemas::CustomFieldJsonCacheKeyMixin)
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

      it "busts the cache on a different cache_key" do
        allow(custom_field)
          .to receive(:cache_key)
          .and_return("something else")

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
