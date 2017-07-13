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
#++

require 'spec_helper'

describe AttributeHelpText::WorkPackage, type: :model do
  describe '.available_attributes' do
    subject { described_class.available_attributes }
    it 'returns an array of potential attributes' do
      expect(subject).to be_a Hash
    end
  end

  describe '.used_attributes' do
    let!(:instance) { FactoryGirl.create :work_package_help_text }
    subject { described_class.used_attributes instance.type }

    it 'returns used attributes' do
      expect(subject).to eq([instance.attribute_name])
    end
  end

  describe '.visible' do
    let(:project) { FactoryGirl.create(:project) }
    let(:role) { FactoryGirl.create(:role, permissions: permissions) }
    let(:user) do
      FactoryGirl.create(:user,
                         member_in_project: project,
                         member_through_role: role)
    end
    let(:permission) { [] }
    let(:static_instance) { FactoryGirl.create :work_package_help_text, attribute_name: 'project' }
    let(:cf_instance) do
      custom_field = FactoryGirl.create :text_wp_custom_field
      FactoryGirl.create :work_package_help_text, attribute_name: "custom_field_#{custom_field.id}"
    end

    subject { FactoryGirl.build :work_package_help_text }

    before do
      # need to clear the cache to free the memoized
      # Type.translated_work_package_form_attributes
      Rails.cache.clear

      static_instance
      cf_instance
    end

    subject { described_class.visible(user) }

    context 'user having no permission' do
      let(:user) do
        FactoryGirl.create(:user)
      end

      it 'returns the help text for the static attribute but not the one for the custom field' do
        is_expected
          .to match_array([static_instance])
      end
    end

    context 'user having the `edit_projects` permission' do
      let(:permissions) { [:edit_projects] }

      it 'returns the help text for the static and cf attribute' do
        is_expected
          .to match_array([static_instance, cf_instance])
      end
    end

    context 'user being member in a project with activated custom fields' do
      let(:permissions) { [] }
      let(:type) do
        type = FactoryGirl.create(:type)
        project.types << type

        type
      end
      let(:cf_instance_active) do
        custom_field = FactoryGirl.create(:text_wp_custom_field)
        project.work_package_custom_fields << custom_field
        type.custom_fields << custom_field
        FactoryGirl.create :work_package_help_text, attribute_name: "custom_field_#{custom_field.id}"
      end
      let(:cf_instance_inactive) do
        cf_instance
      end
      let(:cf_instance_inactive_no_type) do
        custom_field = FactoryGirl.create(:text_wp_custom_field)
        project.work_package_custom_fields << custom_field
        FactoryGirl.create :work_package_help_text, attribute_name: "custom_field_#{custom_field.id}"
      end
      let(:cf_instance_inactive_not_in_project) do
        custom_field = FactoryGirl.create(:text_wp_custom_field)
        type.custom_fields << custom_field
        FactoryGirl.create :work_package_help_text, attribute_name: "custom_field_#{custom_field.id}"
      end
      let(:cf_instance_for_all) do
        custom_field = FactoryGirl.create(:text_wp_custom_field, is_for_all: true)
        FactoryGirl.create :work_package_help_text, attribute_name: "custom_field_#{custom_field.id}"
      end

      before do
        cf_instance_active
        cf_instance_inactive
        cf_instance_inactive_no_type
        cf_instance_inactive_not_in_project
        cf_instance_for_all
      end

      it 'returns the help text for the static and active cf attributes' do
        is_expected
          .to match_array([static_instance, cf_instance_active, cf_instance_for_all])
      end
    end
  end

  describe 'validations' do
    before do
      allow(described_class).to receive(:available_attributes).and_return(status: 'Status')
    end

    let(:attribute_name) { 'status' }
    let(:help_text) { 'foobar' }

    subject { described_class.new attribute_name: attribute_name, help_text: help_text }

    context 'help_text is nil' do
      let(:help_text) { nil }

      it 'validates presence of help text' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:help_text].count).to eql(1)
        expect(subject.errors[:help_text].first)
          .to eql(I18n.t('activerecord.errors.messages.blank'))
      end
    end

    context 'attribute_name is nil' do
      let(:attribute_name) { nil }

      it 'validates presence of attribute name' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:attribute_name].count).to eql(1)
        expect(subject.errors[:attribute_name].first)
          .to eql(I18n.t('activerecord.errors.messages.inclusion'))
      end
    end

    context 'attribute_name is invalid' do
      let(:attribute_name) { 'foobar' }

      it 'validates inclusion of attribute name' do
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:attribute_name].count).to eql(1)
        expect(subject.errors[:attribute_name].first)
          .to eql(I18n.t('activerecord.errors.messages.inclusion'))
      end
    end
  end

  describe 'instance' do
    subject { FactoryGirl.build :work_package_help_text }

    it 'provides a caption of its type' do
      expect(subject.attribute_scope).to eq 'WorkPackage'
      expect(subject.type_caption).to eq I18n.t(:label_work_package)
    end
  end
end
