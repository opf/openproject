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

RSpec.describe API::V3::WorkPackages::WorkPackagePayloadRepresenter do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    build_stubbed(:work_package,
                  start_date: Time.zone.today.to_datetime,
                  due_date: Time.zone.today.to_datetime,
                  created_at: DateTime.now,
                  updated_at: DateTime.now,
                  budget:,
                  type: build_stubbed(:type)) do |wp|
      allow(wp)
        .to receive(:available_custom_fields)
        .and_return(available_custom_fields)
    end
  end
  let(:budget) { build_stubbed(:budget) }
  let(:representer) do
    described_class
      .create(work_package, current_user: user)
  end
  let(:available_custom_fields) { [] }
  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user, &:allow_everything)
    allow(work_package).to receive(:lock_version).and_return(1)
  end

  context "for generation" do
    subject(:generated) { representer.to_json }

    describe "work_package" do
      it { is_expected.to have_json_path("subject") }

      it_behaves_like "API V3 formattable", "description" do
        let(:format) { "markdown" }
        let(:raw) { work_package.description }
        let(:html) { "<p class=\"op-uc-p\">#{work_package.description}</p>" }
      end

      describe "lock version" do
        it { is_expected.to have_json_path("lockVersion") }

        it { is_expected.to have_json_type(Integer).at_path("lockVersion") }

        it { is_expected.to be_json_eql(work_package.lock_version.to_json).at_path("lockVersion") }

        context "with only change_work_package_status permission" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project :change_work_package_status, project: work_package.project
            end
          end

          it { is_expected.to have_json_path("lockVersion") }
        end

        context "with a lock version of nil (new work package)" do
          before do
            allow(work_package)
              .to receive(:lock_version)
              .and_return(nil)
          end

          it "has a lockVersion of 0" do
            expect(subject)
              .to be_json_eql(0)
              .at_path("lockVersion")
          end
        end
      end

      describe "estimated hours" do
        context "when not set" do
          it { is_expected.to have_json_type(NilClass).at_path("estimatedTime") }
        end

        context "when set" do
          let(:work_package) { build(:work_package, estimated_hours: 2) }

          it { is_expected.to have_json_type(String).at_path("estimatedTime") }

          it "has a ISO duration representation (PT2H for instance)" do
            expect(subject).to be_json_eql("PT2H".to_json).at_path("estimatedTime")
          end
        end
      end

      describe "remaining hours" do
        context "when not set" do
          it { is_expected.not_to have_json_path("remainingTime") }
        end

        context "when set" do
          let(:work_package) { build(:work_package, estimated_hours: 7, remaining_hours: 5) }

          it { is_expected.to have_json_type(String).at_path("remainingTime") }

          it "has a ISO duration representation (PT2H for instance)" do
            expect(subject).to be_json_eql("PT5H".to_json).at_path("remainingTime")
          end
        end
      end

      describe "derived remaining hours" do
        context "when set" do
          let(:work_package) { build(:work_package, derived_remaining_hours: 5) }

          it { is_expected.not_to have_json_path("derivedRemainingTime") }
        end
      end

      describe "startDate" do
        before do
          allow(work_package)
            .to receive(:milestone?)
            .and_return(false)

          allow(work_package)
            .to receive(:leaf?)
            .and_return(true)
        end

        it_behaves_like "has ISO 8601 date only" do
          let(:date) { work_package.start_date }
          let(:json_path) { "startDate" }
        end

        context "with no start date" do
          let(:work_package) { build(:work_package, start_date: nil) }

          it "renders as null" do
            expect(subject).to be_json_eql(nil.to_json).at_path("startDate")
          end
        end

        context "when the work_package is a milestone" do
          before do
            allow(work_package)
              .to receive(:milestone?)
              .and_return(true)
          end

          it "has no date attribute" do
            expect(subject).not_to have_json_path("startDate")
          end
        end
      end

      describe "dueDate" do
        before do
          allow(work_package)
            .to receive(:milestone?)
            .and_return(false)

          allow(work_package)
            .to receive(:leaf?)
            .and_return(true)
        end

        it_behaves_like "has ISO 8601 date only" do
          let(:date) { work_package.due_date }
          let(:json_path) { "dueDate" }
        end

        context "when no finish date" do
          let(:work_package) { build(:work_package, due_date: nil) }

          it "renders as null" do
            expect(subject).to be_json_eql(nil.to_json).at_path("dueDate")
          end
        end

        context "when the work_package is a milestone" do
          before do
            allow(work_package)
              .to receive(:milestone?)
              .and_return(true)
          end

          it "has no date attribute" do
            expect(subject).not_to have_json_path("dueDate")
          end
        end
      end

      describe "date" do
        before do
          allow(work_package)
            .to receive(:milestone?)
            .and_return(true)

          allow(work_package)
            .to receive(:leaf?)
            .and_return(true)
        end

        it_behaves_like "has ISO 8601 date only" do
          let(:date) { work_package.due_date }
          let(:json_path) { "date" }
        end

        context "when no finish date" do
          let(:work_package) do
            build_stubbed(:work_package,
                          type: build_stubbed(:type),
                          due_date: nil)
          end

          it "renders as null" do
            expect(subject).to be_json_eql(nil.to_json).at_path("date")
          end
        end

        context "when the work_package is no milestone" do
          before do
            allow(work_package)
              .to receive(:milestone?)
              .and_return(false)
          end

          it "has no date attribute" do
            expect(subject).not_to have_json_path("date")
          end
        end
      end
    end

    describe "_links" do
      let(:path) { "_links/#{property}/href" }

      it { is_expected.to have_json_path("_links") }

      shared_examples_for "linked property" do
        before do
          unless defined?(link) && defined?(property)
            raise "Requires to have 'property' and 'link' defined"
          end
        end

        it { expect(subject).to be_json_eql(link.to_json).at_path(path) }
      end

      shared_examples_for "linked property with 0 value" do |attribute, association = attribute|
        context "with a 0 for #{attribute}_id" do
          before do
            work_package.send(:"#{association}_id=", 0)
          end

          it_behaves_like "linked property" do
            let(:property) { attribute }
            let(:link) { nil }
          end
        end
      end

      describe "status" do
        let(:status) { build_stubbed(:status) }

        before do
          work_package.status = status
        end

        it_behaves_like "linked property" do
          let(:property) { "status" }
          let(:link) { "/api/v3/statuses/#{status.id}" }
        end

        it_behaves_like "linked property with 0 value", :status
      end

      describe "assignee and responsible" do
        let(:other_user) { build_stubbed(:user) }
        let(:link) { "/api/v3/users/#{other_user.id}" }

        describe "assignee" do
          before do
            work_package.assigned_to = other_user
          end

          it_behaves_like "linked property" do
            let(:property) { "assignee" }
          end

          it_behaves_like "linked property with 0 value", :assignee, :assigned_to
        end

        describe "responsible" do
          before do
            work_package.responsible = other_user
          end

          it_behaves_like "linked property" do
            let(:property) { "responsible" }
          end

          it_behaves_like "linked property with 0 value", :responsible
        end
      end

      describe "version" do
        let(:version) { build_stubbed(:version) }

        before do
          work_package.version = version
        end

        it_behaves_like "linked property" do
          let(:property) { "version" }
          let(:link) { "/api/v3/versions/#{version.id}" }
        end

        it_behaves_like "linked property with 0 value", :version, :version
      end

      describe "category" do
        let(:category) { build_stubbed(:category) }

        before do
          work_package.category = category
        end

        it_behaves_like "linked property" do
          let(:property) { "category" }
          let(:link) { "/api/v3/categories/#{category.id}" }
        end

        it_behaves_like "linked property with 0 value", :category
      end

      describe "priority" do
        let(:priority) { build_stubbed(:priority) }

        before do
          work_package.priority = priority
        end

        it_behaves_like "linked property" do
          let(:property) { "priority" }
          let(:link) { "/api/v3/priorities/#{priority.id}" }
        end

        it_behaves_like "linked property with 0 value", :priority
      end

      describe "parent" do
        context "with a parent" do
          let(:parent) { build_stubbed(:work_package) }

          before do
            work_package.parent = parent
            allow(parent)
              .to receive(:visible?)
              .and_return(true)
          end

          it_behaves_like "linked property" do
            let(:property) { "parent" }
            let(:link) { "/api/v3/work_packages/#{parent.id}" }
          end
        end

        context "without a parent" do
          it_behaves_like "linked property" do
            let(:property) { :parent }
            let(:link) { nil }
          end
        end
      end

      describe "budgets" do
        context "without a cost object assigned" do
          let(:budget) { nil }

          it_behaves_like "linked property" do
            let(:property) { :budget }
            let(:link) { nil }
          end
        end

        context "with a cost object assigned" do
          it_behaves_like "linked property" do
            let(:property) { :budget }
            let(:link) { api_v3_paths.budget(budget.id) }
          end
        end

        context "without necessary permissions" do
          before do
            mock_permissions_for(user, &:forbid_everything)
          end

          it "has no href" do
            expect(subject)
              .not_to have_json_path("_links/budget")
          end
        end
      end
    end

    describe "custom fields" do
      let(:available_custom_fields) { [build_stubbed(:integer_wp_custom_field)] }

      it "uses a CustomFieldInjector" do
        allow(API::V3::Utilities::CustomFieldInjector).to receive(:create_value_representer)
          .and_call_original
        representer.to_json
        expect(API::V3::Utilities::CustomFieldInjector).to have_received(:create_value_representer)
      end
    end

    describe "caching" do
      it "does not cache" do
        representer.to_json

        allow(Rails.cache)
          .to receive(:fetch)

        representer.to_json

        expect(Rails.cache)
          .not_to have_received(:fetch)
      end
    end
  end

  describe "parsing" do
    let(:attributes) { {} }
    let(:links) { {} }
    let(:json) do
      copy = attributes.clone
      copy[:_links] = links
      copy.to_json
    end
    let(:work_package) { WorkPackage.new }

    subject { representer.from_json(json) }

    shared_examples_for "settable ISO 8601 date only" do
      let(:attributes) do
        {
          property => date_string
        }
      end

      context "with an ISO formatted date" do
        let(:date_string) { "2015-01-31" }

        it "sets the date" do
          expect(subject.send(method)).to eql(Date.new(2015, 1, 31))
        end
      end

      context "with null" do
        let(:date_string) { nil }

        it "sets the date to nil" do
          expect(subject.send(method)).to be_nil
        end
      end

      context "with a non ISO formatted date" do
        let(:date_string) { "31.01.2015" }

        it "raises an error" do
          expect { subject }.to raise_error(API::Errors::PropertyFormatError)
        end
      end

      context "with an ISO formatted date and time" do
        let(:date_string) { "2015-01-31T13:37:00Z" }

        it "raises an error" do
          expect { subject }.to raise_error(API::Errors::PropertyFormatError)
        end
      end
    end

    describe "scheduleManually" do
      let(:value) { raise "define value" }

      let(:attributes) { { scheduleManually: value } }

      context "with true" do
        let(:value) { true }

        it "reads true" do
          expect(subject.schedule_manually).to be true
        end
      end

      context "with false" do
        let(:value) { false }

        it "reads false" do
          expect(subject.schedule_manually).to be false
        end
      end
    end

    describe "startDate" do
      it_behaves_like "settable ISO 8601 date only" do
        let(:property) { :startDate }
        let(:method) { :start_date }
      end
    end

    describe "dueDate" do
      it_behaves_like "settable ISO 8601 date only" do
        let(:property) { :dueDate }
        let(:method) { :due_date }
      end
    end

    describe "date" do
      before do
        allow(work_package)
          .to receive(:milestone?)
          .and_return(true)

        # Setting values to ensure they are later set to nil in one of the test cases
        work_package.start_date = work_package.due_date = Time.zone.today
      end

      it_behaves_like "settable ISO 8601 date only" do
        let(:property) { :date }
        let(:method) { :due_date }

        context "with an ISO formatted date" do
          let(:date_string) { "2015-01-31" }

          it "sets the start and the due_date" do
            expect(subject.start_date).to eql(Date.new(2015, 1, 31))
            expect(subject.due_date).to eql(Date.new(2015, 1, 31))
          end
        end
      end
    end

    shared_examples_for "linked resource" do
      let(:path) { api_v3_paths.send(attribute_name, id) }
      let(:association_name) { "#{attribute_name}_id" }
      let(:id) { work_package.send(association_name).to_i + 1 }
      let(:links) do
        { attribute_name => href }
      end
      let(:representer_attribute) { subject.send(association_name) }

      describe "with a valid href" do
        let(:href) { { href: path } }

        it "sets attribute to the specified id" do
          expect(representer_attribute.to_i).to eql(id)
        end
      end

      describe "with a null href" do
        let(:href) { { href: nil } }

        it "sets attribute to nil" do
          expect(representer_attribute).to be_nil
        end
      end

      describe "with an invalid link" do
        let(:href) { {} }

        !let(:old_id) { work_package.send(association_name) }

        it "leaves attribute unchanged" do
          expect(representer_attribute).to eql(old_id)
        end
      end
    end

    describe "project" do
      it_behaves_like "linked resource" do
        let(:attribute_name) { "project" }
      end
    end

    describe "version" do
      before do
        work_package.version_id = 1
      end

      it_behaves_like "linked resource" do
        let(:attribute_name) { "version" }
        let(:association_name) { "version_id" }
      end
    end

    describe "type" do
      it_behaves_like "linked resource" do
        let(:attribute_name) { "type" }
      end
    end

    describe "status" do
      it_behaves_like "linked resource" do
        let(:attribute_name) { "status" }
      end
    end

    describe "assignee" do
      let(:attribute_name) { "assignee" }

      before do
        work_package.assigned_to_id = 1
      end

      context "with a user" do
        it_behaves_like "linked resource" do
          let(:path) { api_v3_paths.user(id) }
          let(:association_name) { "assigned_to_id" }
        end
      end

      context "with a group" do
        it_behaves_like "linked resource" do
          let(:path) { api_v3_paths.group(id) }
          let(:association_name) { "assigned_to_id" }
        end
      end
    end

    describe "responsible" do
      let(:attribute_name) { "responsible" }

      before do
        work_package.responsible_id = 1
      end

      context "with a user" do
        it_behaves_like "linked resource" do
          let(:path) { api_v3_paths.user(id) }
        end
      end

      context "with a group" do
        it_behaves_like "linked resource" do
          let(:path) { api_v3_paths.group(id) }
        end
      end
    end

    describe "category" do
      before do
        work_package.category_id = 1
      end

      it_behaves_like "linked resource" do
        let(:attribute_name) { "category" }
      end
    end

    describe "parent" do
      let(:parent) { build_stubbed(:work_package) }
      let(:new_parent) do
        wp = build_stubbed(:work_package)
        allow(WorkPackage)
          .to receive(:find_by)
          .with(id: wp.id.to_s)
          .and_return(wp)
        wp
      end
      let(:path) { api_v3_paths.work_package(new_parent.id) }
      let(:links) do
        { parent: href }
      end

      before do
        work_package.parent = parent
      end

      describe "with a valid href" do
        let(:href) { { href: path } }

        it "sets attribute to the specified id" do
          expect(subject.parent).to eql(new_parent)
        end
      end

      describe "with a null href" do
        let(:href) { { href: nil } }

        it "sets attribute to nil" do
          expect(subject.parent).to be_nil
        end
      end

      describe "with an invalid link" do
        let(:href) { {} }

        it "leaves attribute unchanged" do
          expect(subject.parent).to eql(parent)
        end
      end
    end
  end
end
