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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::ImportService do
  subject(:service) { described_class.new(user:, project:) }

  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:bug) { create(:type_bug, name: "Bug") }
  shared_let(:project) { create(:project, types: [type, bug]) }
  shared_let(:status) { create(:default_status, name: "New") }
  shared_let(:priority) { create(:default_priority, name: "Normal") }
  shared_let(:category) { create(:category, project:, name: "Backend") }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  def row(values, number: 2)
    WorkPackages::Import::CSV::Parser::Row.new(number:, values:, problems: [])
  end

  def import(rows, dry_run: false)
    service.call(rows:, dry_run:)
  end

  describe "a clean file" do
    let(:rows) do
      [row({ subject: "Write the docs", type: "Task", category: "Backend" }, number: 2),
       row({ subject: "Fix the bug", type: "Bug" }, number: 3)]
    end

    it "creates every row" do
      expect { import(rows) }.to change(WorkPackage, :count).by(2)
    end

    it "reports what it created" do
      result = import(rows)

      expect(result).to be_success
      expect(result.result).to have_attributes(row_count: 2, created_count: 2, problems: [])
    end

    it "names the work packages it created, so the view can list exactly those" do
      expect(import(rows).result.created_ids).to eq(WorkPackage.order(:id).pluck(:id))
    end

    it "assigns the attributes the rows carry" do
      import(rows)

      expect(WorkPackage.find_by(subject: "Write the docs"))
        .to have_attributes(type:, category:, project:, author: user)
    end

    it "counts what was created, defaults included" do
      expect(import(rows).result.counts)
        .to eq("type" => { "Task" => 1, "Bug" => 1 },
               "status" => { "New" => 2 },
               "priority" => { "Normal" => 2 },
               "category" => { "Backend" => 1 })
    end

    # The job runs in the importing user's language, and the report is read in the reader's, so a
    # caption as the key would leave a German run unreadable to everyone else.
    it "keys the counts by attribute, not by whatever the caption is in the current language" do
      counts = I18n.with_locale(:de) do
        expect(WorkPackage.human_attribute_name(:type)).to eq("Typ")
        import(rows).result.counts
      end

      expect(counts.keys).to contain_exactly("type", "status", "priority", "category")
    end

    it "sends no notifications" do
      expect { import(rows) }.not_to change(Notification, :count)
    end
  end

  describe "the view it saves" do
    let(:rows) do
      [row({ subject: "Write the docs" }, number: 2),
       row({ subject: "Fix the bug" }, number: 3)]
    end

    let(:view) { Query.find(import(rows).result.query_id) }

    it "is private to the importer, in the project that was imported into" do
      expect(view).to have_attributes(user:, project:, public: false)
    end

    it "is named after the moment of the run" do
      expect(view.name).to match(/\ACSV import on .+/)
    end

    it "is listed in the sidebar, which passes over a query carrying no view of its own" do
      expect(view.views.pluck(:type)).to eq(%w[work_packages_table])
      expect(view.hidden).to be(false)
    end

    it "filters on exactly the work packages the run created" do
      created = import(rows).result.created_ids
      saved = Query.find_by(user:)

      expect(saved.filters.map { |filter| [filter.field.to_s, filter.operator, filter.values] })
        .to eq([["id", "=", created.map(&:to_s)]])
    end

    it "is saved for an importer who may not save views of their own" do
      user.members.first.roles.first.update!(permissions: %i[view_work_packages add_work_packages])

      expect(view.user).to eq(user)
    end

    it "outlives nothing: a run that fails saves no view" do
      expect { import([row({ subject: "" }, number: 2)]) }.to not_change(Query, :count).and not_change(View, :count)
    end
  end

  describe "a dry run" do
    let(:rows) { [row({ subject: "Write the docs" })] }

    it "persists nothing" do
      expect { import(rows, dry_run: true) }.not_to change(WorkPackage, :count)
    end

    it "saves no view, since there is nothing to look at afterwards" do
      expect { import(rows, dry_run: true) }.to not_change(Query, :count).and not_change(View, :count)
      expect(import(rows, dry_run: true).result.query_id).to be_nil
    end

    it "reports what would have been created" do
      result = import(rows, dry_run: true)

      expect(result).to be_success
      expect(result.result).to have_attributes(row_count: 1, created_count: 1, problems: [])
      expect(result.result.counts).to include("type" => { "Task" => 1 })
    end
  end

  describe "a file with a bad row" do
    let(:rows) do
      [row({ subject: "Write the docs" }, number: 2),
       row({ subject: "" }, number: 3),
       row({ subject: "Fix the bug" }, number: 4)]
    end

    it "rolls back the rows that would have worked" do
      expect { import(rows) }.not_to change(WorkPackage, :count)
    end

    it "attempts every row rather than stopping at the first failure" do
      result = import(rows)

      expect(result).to be_failure
      expect(result.result).to have_attributes(row_count: 3, created_count: 2)
    end

    it "attributes the problem to the row, the column and the value" do
      problem = import(rows).result.problems.sole

      expect(problem).to have_attributes(row: 3, attribute: "subject", value: "")
      expect(problem.message).to eq("can't be blank.")
    end
  end

  describe "the Created on and Updated on columns" do
    let(:created_at) { Time.utc(2024, 3, 4, 9, 30) }
    let(:updated_at) { Time.utc(2024, 5, 6, 11, 15) }
    let(:rows) do
      [row({ subject: "Imported from elsewhere",
             created_at: created_at.iso8601,
             updated_at: updated_at.iso8601 })]
    end

    it "moves the work package back in time" do
      import(rows)

      expect(WorkPackage.sole).to have_attributes(created_at:, updated_at:)
    end

    it "moves the creation journal with it" do
      import(rows)

      journal = WorkPackage.sole.journals.first

      expect(journal).to have_attributes(created_at:, updated_at: created_at)
      expect(journal.validity_period).to eq(created_at..)
    end

    it "exists for a baseline asked about a moment after it was created" do
      import(rows)

      expect(WorkPackage.at_timestamp(Timestamp.new((created_at + 1.day).iso8601)).pluck(:subject))
        .to eq(["Imported from elsewhere"])
    end

    it "does not exist for a baseline asked about a moment before it was created" do
      import(rows)

      expect(WorkPackage.at_timestamp(Timestamp.new((created_at - 1.day).iso8601))).to be_empty
    end

    it "leaves a row without the columns alone" do
      import([row({ subject: "Written today" })])

      expect(WorkPackage.sole.created_at).to be > 1.minute.ago
    end

    it "moves the journal only when Created on says so" do
      import([row({ subject: "Touched later", updated_at: updated_at.iso8601 })])

      work_package = WorkPackage.sole

      expect(work_package.updated_at).to eq(updated_at)
      expect(work_package.journals.first.created_at).to be > 1.minute.ago
    end
  end

  describe "a row that fails without saying why" do
    let(:rows) do
      [row({ subject: "Write the docs" }, number: 2),
       row({ subject: "Fix the bug" }, number: 3)]
    end

    before do
      call_count = 0
      allow_any_instance_of(WorkPackages::CreateService) # rubocop:disable RSpec/AnyInstance
        .to receive(:call).and_wrap_original do |original, **args|
          call_count += 1
          call_count == 2 ? ServiceResult.failure : original.call(**args)
        end
    end

    it "rolls back the rows that did land" do
      expect { import(rows) }.not_to change(WorkPackage, :count)
    end

    it "fails rather than reporting a success that is missing a row" do
      result = import(rows)

      expect(result).to be_failure
      expect(result.result).to have_attributes(row_count: 2, created_count: 1)
    end

    it "says the row could not be created rather than showing an empty problem list" do
      problem = import(rows).result.problems.sole

      expect(problem).to have_attributes(row: 3, attribute: nil, value: nil)
      expect(problem.message).to eq("could not be created, and no reason was reported.")
    end
  end

  describe "problems the mapper found" do
    let(:rows) { [row({ subject: "Write the docs", type: "Milestone" }, number: 5)] }

    it "reports them without reaching the create service" do
      allow(WorkPackages::CreateService).to receive(:new).and_call_original

      result = import(rows)

      expect(WorkPackages::CreateService).not_to have_received(:new)
      expect(result.result.problems.sole)
        .to have_attributes(row: 5, attribute: "type", value: "Milestone")
    end
  end

  describe "a problem the contract raises against no single column" do
    let(:rows) { [row({ subject: "Write the docs" })] }

    before do
      allow_any_instance_of(WorkPackages::CreateContract) # rubocop:disable RSpec/AnyInstance
        .to receive(:validate) { |contract| contract.errors.add(:base, :error_unauthorized) && false }
    end

    it "keeps the message whole and leaves the column empty" do
      problem = import(rows).result.problems.sole

      expect(problem).to have_attributes(row: 2, attribute: nil, value: nil)
      expect(problem.message).to be_present
    end
  end
end
