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

RSpec.describe WorkPackageTypes::BuildProjectVariantsJob, with_flag: { type_variants: true } do
  let(:kept_field) { create(:work_package_custom_field, is_for_all: false) }
  let(:dropped_field) { create(:work_package_custom_field, is_for_all: false) }

  let!(:type) do
    create(:type, name: "Bug", custom_fields: [kept_field, dropped_field]).tap do |type|
      type.attribute_groups = [["custom group", %w[assignee] + [kept_field, dropped_field].map(&:attribute_name)]]
      type.save!
    end
  end

  let!(:narrowing_project) do
    create(:project, name: "Website Relaunch", types: [type], work_package_custom_fields: [kept_field])
  end

  let!(:complete_project) do
    create(:project, name: "Intranet", types: [type], work_package_custom_fields: [kept_field, dropped_field])
  end

  def resolved_type(project)
    project.reload.project_types.sole.effective_type
  end

  subject(:run_job) { described_class.perform_now }

  before { RequestStore.clear! }

  it "builds a variant only for the project that narrows the form configuration" do
    expect { run_job }.to change(Type, :count).by(1)

    expect(resolved_type(narrowing_project).own_name).to eq("Bug - Website Relaunch")
    expect(resolved_type(complete_project)).to eq(type)
  end

  it "resolves the narrowing project to its variant" do
    run_job

    variant = resolved_type(narrowing_project)

    expect(variant).to be_variant
    expect(variant.parent).to eq(type)
    expect(variant.custom_fields).to contain_exactly(kept_field)
  end

  it "keeps the project on the shared root type" do
    run_job

    expect(narrowing_project.reload.types).to contain_exactly(type)
  end

  it "leaves the root type untouched" do
    run_job

    expect(type.reload.custom_fields).to contain_exactly(kept_field, dropped_field)
    expect(type.configuration_links).to be_empty
  end

  it "does not retype the work packages" do
    work_package = create(:work_package, project: narrowing_project, type:)

    expect { run_job }.not_to change { work_package.reload.type_id }
  end

  it "is idempotent" do
    run_job

    expect { described_class.perform_now }.not_to change(Type, :count)
    expect(resolved_type(narrowing_project).own_name).to eq("Bug - Website Relaunch")
  end

  context "when a project already resolves to a variant that narrows further" do
    let(:third_field) { create(:work_package_custom_field, is_for_all: false) }

    let!(:type) do
      create(:type, name: "Bug", custom_fields: [kept_field, dropped_field, third_field]).tap do |type|
        type.attribute_groups = [
          ["custom group", %w[assignee] + [kept_field, dropped_field, third_field].map(&:attribute_name)]
        ]
        type.save!
      end
    end

    let!(:variant) { create(:type, name: "Regression", parent: type) }

    let!(:narrowing_project) do
      create(:project, name: "Website Relaunch", types: [variant], work_package_custom_fields: [kept_field])
    end

    it "builds the new variant from the resolved variant rather than the root" do
      run_job

      built = resolved_type(narrowing_project)

      expect(built.own_name).to eq("Regression - Website Relaunch")
      expect(built.source_for(Type::ConfigurationLink::FORM_CONFIGURATION)).to eq(variant)
      expect(built.custom_fields).to contain_exactly(kept_field)
    end
  end

  context "when the project is archived" do
    let!(:narrowing_project) do
      create(:project, :archived, name: "Website Relaunch", types: [type], work_package_custom_fields: [kept_field])
    end

    it "builds the variant anyway, as an archived project cannot be configured by hand" do
      run_job

      variant = resolved_type(narrowing_project)

      expect(variant).to be_variant
      expect(variant.custom_fields).to contain_exactly(kept_field)
    end
  end

  context "when the type_variants feature is inactive", with_flag: { type_variants: false } do
    it "refuses to run, as exclusions would have no effect" do
      expect { run_job }.to raise_error(/type_variants/)
      expect(resolved_type(narrowing_project)).to eq(type)
    end
  end

  context "when one project fails" do
    before do
      allow(Projects::Types::SwitchVariantService)
        .to receive(:new)
        .and_return(instance_double(Projects::Types::SwitchVariantService,
                                    call: ServiceResult.failure(errors: ActiveModel::Errors.new(Project.new))))
    end

    it "logs the failure and keeps going" do
      allow(Rails.logger).to receive(:error)

      expect { run_job }.not_to raise_error
      expect(Rails.logger).to have_received(:error)
    end

    it "leaves no variant behind that no project resolves to" do
      allow(Rails.logger).to receive(:error)

      expect { run_job }.not_to change(Type, :count)
    end
  end
end
