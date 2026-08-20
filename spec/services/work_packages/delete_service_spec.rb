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

RSpec.describe WorkPackages::DeleteService do
  let(:user) do
    build_stubbed(:user)
  end
  let(:work_package) do
    build_stubbed(:work_package, type: build_stubbed(:type))
  end
  let(:instance) do
    described_class
      .new(user:,
           model: work_package)
  end
  let(:destroyed_result) { true }
  let(:destroy_allowed) { true }

  subject { instance.call }

  before do
    allow(work_package).to receive(:reload).and_return(work_package)
    expect(work_package).to receive(:destroy).and_return(destroyed_result)
    allow(work_package).to receive(:destroyed?).and_return(destroyed_result)

    mock_permissions_for(user) do |mock|
      mock.allow_in_project :delete_work_packages, project: work_package.project
    end
  end

  it "destroys the work package" do
    subject
  end

  it "is successful" do
    expect(subject)
      .to be_success
  end

  it "returns the destroyed work package" do
    expect(subject.result)
      .to eql work_package
  end

  it "returns an empty errors array" do
    expect(subject.errors)
      .to be_empty
  end

  context "when the work package could not be destroyed" do
    let(:destroyed_result) { false }

    it "is no success" do
      expect(subject)
        .not_to be_success
    end
  end

  context "with ancestors" do
    let(:parent) do
      build_stubbed(:work_package)
    end
    let(:grandparent) do
      build_stubbed(:work_package)
    end
    let(:update_ancestors_service_instance) do
      update_ancestors_service_instance = instance_double(WorkPackages::UpdateAncestorsService)

      service_result = ServiceResult.success(result: work_package,
                                             dependent_results: [ServiceResult.success(result: parent),
                                                                 ServiceResult.success(result: grandparent)])

      allow(update_ancestors_service_instance)
        .to receive_messages(
          with_state: update_ancestors_service_instance,
          call: service_result
        )

      update_ancestors_service_instance
    end

    before do
      allow(WorkPackages::UpdateAncestorsService)
        .to receive(:new)
        .and_return(update_ancestors_service_instance)
    end

    it "calls the inherit attributes service for each ancestor" do
      subject
      expect(WorkPackages::UpdateAncestorsService)
        .to have_received(:new).with(user:, work_package:)
      expect(update_ancestors_service_instance)
        .to have_received(:call).with(work_package.attributes.keys.map(&:to_sym))
    end

    context "when the work package could not be destroyed" do
      let(:destroyed_result) { false }

      it "does not call inherited attributes service" do
        subject
        expect(WorkPackages::UpdateAncestorsService)
          .not_to have_received(:new)
      end
    end
  end

  context "with descendants" do
    let(:child) do
      build_stubbed(:work_package, project: work_package.project, parent: work_package).tap do |wp|
        allow(wp).to receive(:reload).and_return(wp)
      end
    end
    let(:grandchild) do
      build_stubbed(:work_package, project: work_package.project, parent: child).tap do |wp|
        allow(wp).to receive(:reload).and_return(wp)
      end
    end
    let(:descendants) do
      [child, grandchild]
    end

    before do
      # The stubbed descendants are not in the database, so no walk can find them.
      # WorkPackages::Shared::DeletionPlanning has its own spec for that.
      allow(instance).to receive_messages(deleted_descendants: descendants, unlinked_descendants: [])

      descendants.each do |descendant|
        allow(descendant)
          .to receive(:destroy)
      end
    end

    it "destroys the descendants" do
      descendants.each do |descendant|
        expect(descendant)
          .to receive(:destroy)
      end

      subject
    end

    it "returns the descendants as part of the result" do
      subject

      expect(subject.all_results)
        .to match_array [work_package] + descendants
    end

    context "if the work package could not be destroyed" do
      let(:destroyed_result) { false }

      it "does not destroy the descendants" do
        descendants.each do |descendant|
          expect(descendant)
            .not_to receive(:destroy)
        end

        subject
      end
    end
  end
end
