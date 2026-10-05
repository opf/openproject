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

RSpec.describe "Type scheme invariants" do # rubocop:disable RSpec/DescribeClass
  let!(:epic) { create(:type, name: "Epic", position: 1) }
  let!(:task) { create(:type, name: "Task", position: 2) }
  let!(:project) { create(:project, types: [epic, task]) }
  let!(:default_scheme) { TypeSchemes::DefaultScheme.ensure! }

  describe "database constraints" do
    it "rejects a second default scheme" do
      other = create(:type_scheme, types: [epic])

      expect { other.update_columns(is_default: true) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a second default item in one scheme" do
      item = default_scheme.items.find { |i| !i.is_default }

      expect { item.update_columns(is_default: true) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects the same type twice in one scheme" do
      expect do
        TypeSchemeItem.insert_all([{ scheme_id: default_scheme.id, type_id: epic.id, position: 9, is_default: false }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects two schemes for one project" do
      TypeSchemes::SchemeService.assign_default(project)

      expect do
        ProjectTypeScheme.insert_all([{ project_id: project.id, scheme_id: default_scheme.id }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "refuses to delete a scheme that is assigned to a project" do
      TypeSchemes::SchemeService.assign_default(project)

      expect { TypeScheme.where(id: default_scheme.id).delete_all }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses to destroy a scheme through the model" do
      expect(default_scheme.destroy).to be false
      expect(TypeScheme.exists?(default_scheme.id)).to be true
    end

    it "removes assignments together with the project" do
      TypeSchemes::SchemeService.assign_default(project)

      expect { project.destroy }.to change(ProjectTypeScheme, :count).by(-1)
      expect(TypeScheme.exists?(default_scheme.id)).to be true
    end
  end

  describe "model guards" do
    it "keeps the default scheme active" do
      default_scheme.active = false

      expect(default_scheme).not_to be_valid
    end

    it "requires exactly one default item on an active scheme" do
      default_scheme.items.each { |item| item.is_default = false }

      expect(default_scheme).not_to be_valid
    end

    it "cannot be deactivated through the service" do
      expect(TypeSchemes::SchemeService.deactivate(default_scheme)).to be_failure
      expect(default_scheme.reload).to be_active
    end
  end

  describe "fail-open behaviour when the invariants are broken" do
    before { TypeSchemes::SchemeService.assign_default(project) }

    it "still resolves a scheme and offers types after the default type was deleted" do
      task.destroy
      TypeSchemes::Resolver.reset_cache
      project.reload

      expect(TypeSchemes::Resolver.for_project(project)).to eq default_scheme
      expect(TypeSchemes::Resolver.allowed_types(project)).to contain_exactly(epic)
    end

    it "falls back to the enabled types when every scheme item is gone" do
      TypeSchemeItem.where(scheme_id: default_scheme.id).delete_all
      TypeSchemes::Resolver.reset_cache

      expect(TypeSchemes::Resolver.allowed_types(project)).to match_array(project.enabled_types)
    end

    it "falls back to the default scheme when the assigned scheme is deactivated by raw SQL" do
      other = create(:type_scheme, types: [epic])
      TypeSchemes::SchemeService.assign(project, other)
      other.update_columns(active: false)
      TypeSchemes::Resolver.reset_cache

      expect(TypeSchemes::Resolver.for_project(project)).to eq default_scheme
    end

    it "resolves nothing and stays native when no scheme exists at all" do
      TypeSchemeItem.delete_all
      ProjectTypeScheme.delete_all
      TypeScheme.delete_all
      TypeSchemes::Resolver.reset_cache

      expect(TypeSchemes::Resolver.for_project(project)).to be_nil
      expect(TypeSchemes::Resolver.allowed_types(project)).to match_array(project.enabled_types)
    end
  end

  describe "recovery" do
    it "is restored by the repair service after a cascading type deletion" do
      task.destroy

      TypeSchemes::Repair.call(dry_run: false)

      expect(default_scheme.reload).to be_valid
      expect(default_scheme.default_type).to eq epic
    end
  end

  describe "core hooks the module prepends" do
    it "still wraps the core methods" do
      expect(WorkPackages::BaseContract.instance_method(:assignable_types).owner)
        .to eq OpenProject::TypeSchemes::ContractPatch
      expect(WorkPackages::BaseContract.private_instance_methods).to include(:validate_enabled_type)
      expect(WorkPackages::SetAttributesService.private_instance_methods).to include(:assign_default_type)
      expect(WorkPackages::SetAttributesService.ancestors.first).to eq OpenProject::TypeSchemes::SetAttributesServicePatch
    end

    it "has a core implementation behind every patched method" do
      core_contract = WorkPackages::BaseContract.ancestors.drop(1).find { |mod| mod.instance_methods(false).include?(:assignable_types) }
      core_service = WorkPackages::SetAttributesService.ancestors.drop(1).find do |mod|
        mod.private_instance_methods(false).include?(:assign_default_type)
      end

      expect(core_contract).to be_present
      expect(core_service).to be_present
    end
  end
end
