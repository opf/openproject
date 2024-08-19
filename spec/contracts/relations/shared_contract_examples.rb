# -- copyright
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
# ++

require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "relation contract" do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:user) }
  let(:relation_from) do
    build_stubbed(:work_package, subject: "From WP") do |wp|
      allow(wp_visible_scope)
        .to receive(:exists?)
              .with(wp.id)
              .and_return(relation_from_visible)
    end
  end
  let(:relation_to) do
    build_stubbed(:work_package, subject: "To WP") do |wp|
      allow(wp_visible_scope)
        .to receive(:exists?)
              .with(wp.id)
              .and_return(relation_to_visible)
    end
  end
  let(:relation_type) do
    Relation::TYPE_RELATES
  end
  let(:relation_lag) { 42 }
  let!(:wp_visible_scope) do
    instance_double(ActiveRecord::Relation).tap do |relation|
      allow(WorkPackage)
        .to receive(:visible)
              .with(current_user)
              .and_return(relation)
    end
  end
  let!(:relatable_scope) do
    scope = instance_double(ActiveRecord::Relation)

    allow(WorkPackage)
      .to receive(:relatable)
            .with(canonical_relation_from, canonical_relation_type, ignored_relation: relation)
            .and_return(scope)

    allow(scope)
      .to receive(:where)
            .with(id: canonical_relation_to.id)
            .and_return(scope)

    allow(scope)
      .to receive(:empty?)
            .and_return(!relatable)

    scope
  end

  # The relation might get reversed by the code under test
  let(:canonical_relation_from) { Relation::TYPES.dig(relation_type, :reverse).present? ? relation_to : relation_from }
  let(:canonical_relation_to) { Relation::TYPES.dig(relation_type, :reverse).present? ? relation_from : relation_to }
  let(:canonical_relation_type) do
    Relation::TYPES.dig(relation_type, :reverse).present? ? Relation::TYPES[relation_type][:reverse] : relation_type
  end

  let(:relation_from_visible) { true }
  let(:relation_to_visible) { true }
  let(:relatable) { true }
  let(:permissions) { [:manage_work_package_relations] }

  subject(:contract) { described_class.new relation, current_user }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: canonical_relation_from.project
    end
  end

  describe "validation" do
    it_behaves_like "contract is valid"

    context "when lacking the necessary permission" do
      let(:permissions) { [] }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when the work package for from is not visible" do
      let(:relation_from_visible) { false }

      it_behaves_like "contract is invalid", from: :error_not_found
    end

    context "when the work package for to is not visible" do
      let(:relation_to_visible) { false }

      it_behaves_like "contract is invalid", to: :error_not_found
    end

    Relation::TYPES.each_key do |available_type|
      context "when having the type '#{available_type}'" do
        let(:relation_type) { available_type }

        it_behaves_like "contract is valid"
      end
    end

    context "when the work package type is unknown" do
      let(:relation_type) { "some_bogus" }

      it_behaves_like "contract is invalid", relation_type: :inclusion
    end
  end

  include_examples "contract reuses the model errors"
end
