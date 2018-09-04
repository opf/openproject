#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++require 'rspec'

require 'spec_helper'
require_relative './eager_loading_mock_wrapper'

describe ::API::V3::WorkPackages::EagerLoading::CustomValue do
  let!(:work_package) { FactoryBot.create(:work_package) }
  let!(:type) { work_package.type }
  let!(:other_type) { FactoryBot.create(:type) }
  let!(:project) { work_package.project }
  let!(:other_project) { FactoryBot.create(:project) }
  let!(:user) { FactoryBot.create(:user) }
  let!(:version) { FactoryBot.create(:version, project: project) }
  let!(:type_project_list_cf) do
    FactoryBot.create(:list_wp_custom_field).tap do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let!(:type_project_user_cf) do
    FactoryBot.create(:user_wp_custom_field).tap do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let!(:type_project_version_cf) do
    FactoryBot.create(:version_wp_custom_field, name: 'blubs').tap do |cf|
      type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let!(:for_all_type_cf) do
    FactoryBot.create(:list_wp_custom_field, is_for_all: true).tap do |cf|
      type.custom_fields << cf
    end
  end
  let!(:for_all_other_type_cf) do
    FactoryBot.create(:list_wp_custom_field, is_for_all: true).tap do |cf|
      other_type.custom_fields << cf
    end
  end
  let!(:type_other_project_cf) do
    FactoryBot.create(:list_wp_custom_field).tap do |cf|
      type.custom_fields << cf
      other_project.work_package_custom_fields << cf
    end
  end
  let!(:other_type_project_cf) do
    FactoryBot.create(:list_wp_custom_field).tap do |cf|
      other_type.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end

  describe '.apply' do
    it 'preloads the custom fields and values' do
      FactoryBot.create(:custom_value,
                        custom_field: type_project_list_cf,
                        customized: work_package,
                        value: type_project_list_cf.custom_options.last.id)

      FactoryBot.build(:custom_value,
                       custom_field: type_project_user_cf,
                       customized: work_package,
                       value: user.id)
                .save(validate: false)

      FactoryBot.create(:custom_value,
                        custom_field: type_project_version_cf,
                        customized: work_package,
                        value: version.id)

      work_package = WorkPackage.first
      wrapped = EagerLoadingMockWrapper.wrap(described_class, [work_package])

      expect(type)
        .not_to receive(:custom_fields)
      expect(project)
        .not_to receive(:all_work_package_custom_fields)

      [CustomOption, User, Version].each do |klass|
        expect(klass)
          .not_to receive(:find_by)
      end

      wrapped.each do |w|
        expect(w.available_custom_fields)
          .to match_array [type_project_list_cf,
                           type_project_version_cf,
                           type_project_user_cf,
                           for_all_type_cf]

        expect(work_package.send(:"custom_field_#{type_project_version_cf.id}"))
          .to eql version
        expect(work_package.send(:"custom_field_#{type_project_list_cf.id}"))
          .to eql type_project_list_cf.custom_options.last.name
        expect(work_package.send(:"custom_field_#{type_project_user_cf.id}"))
          .to eql user
      end
    end
  end

  describe '#usages returning an is_for_all custom field within a project (Regression #28435)' do
    let(:other_project) { FactoryBot.create :project }
    subject { described_class.new [work_package] }

    before do
      # Assume that one custom field has an entry in project_custom_fields
      for_all_type_cf.projects << other_project
    end

    it 'still allows looking up the global custom field in a different project' do
      # Exhibits the same behavior as in regression, usage returns a hash with project_id set for a global
      # custom field
      expect(for_all_type_cf.is_for_all).to eq(true)
      expect(subject.send(:usages))
        .to include("project_id" => other_project.id, "type_id" => type.id, "custom_field_id" => for_all_type_cf.id)

      wrapped = EagerLoadingMockWrapper.wrap(described_class, [work_package])
      expect(wrapped.first.available_custom_fields).to include(for_all_type_cf)
    end
  end
end
