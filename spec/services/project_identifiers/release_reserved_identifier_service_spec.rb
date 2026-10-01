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

RSpec.describe ProjectIdentifiers::ReleaseReservedIdentifierService do
  let!(:project) { create(:project) }
  # All fixtures share one project graph — deliberately NOT the slug-owning
  # project: creating work packages there would auto-seed "old-id-*" aliases
  # in semantic mode and collide with the explicit ones below.
  let(:alias_work_package) { create(:work_package) }
  let!(:matching_aliases) do
    [create(:work_package_semantic_alias, identifier: "old-id-1", work_package: alias_work_package),
     create(:work_package_semantic_alias, identifier: "old-id-2", work_package: alias_work_package)]
  end
  let!(:other_prefix_alias) do
    create(:work_package_semantic_alias, identifier: "old-id-extra-7", work_package: alias_work_package)
  end
  let!(:case_differing_alias) do
    create(:work_package_semantic_alias, identifier: "OLD-ID-3", work_package: alias_work_package)
  end
  let!(:stale_wp) do
    create(:work_package, project: alias_work_package.project)
      .tap { |wp| wp.update_columns(identifier: "old-id-9", sequence_number: 9) }
  end
  let!(:decoy_wp) do
    create(:work_package, project: alias_work_package.project)
      .tap { |wp| wp.update_columns(identifier: "old-id-extra-9", sequence_number: 8) }
  end
  let!(:slug) { FriendlyId::Slug.create!(sluggable: project, slug: "old-id") }

  subject(:service_call) { described_class.new(slug).call }

  # Releasing a slug and removing its aliases happens regardless of the current
  # identifier mode — leftover semantic aliases would otherwise shadow the alias
  # rows of a new project claiming the identifier after a later re-conversion.
  shared_examples "releases the slug and its aliases" do
    it "destroys the slug and returns a successful ServiceResult" do
      expect(service_call).to be_success
      expect(FriendlyId::Slug.exists?(slug.id)).to be(false)
    end

    it "deletes only the exact-prefix aliases" do
      expect { service_call }.to change(WorkPackageSemanticAlias, :count).by(-2)

      remaining = WorkPackageSemanticAlias.pluck(:identifier)
      expect(remaining).to include("old-id-extra-7", "OLD-ID-3")
      expect(remaining).not_to include("old-id-1", "old-id-2")
    end

    context "when destroying the slug fails" do
      before do
        allow(slug).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it "rolls back the alias deletion" do
        expect { service_call }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(WorkPackageSemanticAlias.where(identifier: %w[old-id-1 old-id-2]).count).to eq(2)
      end
    end
  end

  context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
    it_behaves_like "releases the slug and its aliases"

    # In semantic mode the identifier column carries the live semantic
    # identifiers of the projects currently using the mode, so it must be left
    # untouched even when it matches the released prefix.
    it "does not clear work package identifiers" do
      service_call
      expect(stale_wp.reload).to have_attributes(identifier: "old-id-9", sequence_number: 9)
    end
  end

  context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
    it_behaves_like "releases the slug and its aliases"

    it "clears stale identifiers only from work packages carrying the released prefix" do
      service_call
      expect(stale_wp.reload).to have_attributes(identifier: nil, sequence_number: nil)
      expect(decoy_wp.reload).to have_attributes(identifier: "old-id-extra-9", sequence_number: 8)
    end

    context "when destroying the slug fails" do
      before do
        allow(slug).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it "rolls back the work package identifier clearing" do
        expect { service_call }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(stale_wp.reload).to have_attributes(identifier: "old-id-9", sequence_number: 9)
      end
    end
  end
end
