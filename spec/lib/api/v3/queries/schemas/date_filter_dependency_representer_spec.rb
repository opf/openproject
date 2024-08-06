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

RSpec.describe API::V3::Queries::Schemas::DateFilterDependencyRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:query) { build_stubbed(:query, project:) }
  let(:filter) { Queries::WorkPackages::Filter::DueDateFilter.create!(context: query) }
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
        let(:type) { "[1]Integer" }

        context "for operator 'Queries::Operators::InLessThan'" do
          let(:operator) { Queries::Operators::InLessThan }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::InMoreThan'" do
          let(:operator) { Queries::Operators::InMoreThan }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::In'" do
          let(:operator) { Queries::Operators::In }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::ThisWeek'" do
          let(:operator) { Queries::Operators::ThisWeek }

          it_behaves_like "filter dependency empty"
        end

        context "for operator 'Queries::Operators::LessThanAgo'" do
          let(:operator) { Queries::Operators::LessThanAgo }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::MoreThanAgo'" do
          let(:operator) { Queries::Operators::MoreThanAgo }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::Ago'" do
          let(:operator) { Queries::Operators::Ago }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::OnDate'" do
          let(:operator) { Queries::Operators::OnDate }
          let(:type) { "[1]Date" }

          it_behaves_like "filter dependency"
        end

        context "for operator 'Queries::Operators::BetweenDate'" do
          let(:operator) { Queries::Operators::BetweenDate }
          let(:type) { "[2]Date" }

          it_behaves_like "filter dependency"
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
