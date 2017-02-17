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

describe WorkPackage, type: :model do
  describe '#custom_fields' do
    let(:type) { FactoryGirl.create(:type_standard) }
    let(:project) { FactoryGirl.create(:project, types: [type]) }
    let(:work_package) {
      FactoryGirl.build(:work_package,
                        project: project,
                        type: type)
    }
    let (:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name: 'Database',
                         field_format: 'list',
                         possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                         is_required: true)
    }

    shared_context 'project with required custom field' do
      before do
        project.work_package_custom_fields << custom_field
        type.custom_fields << custom_field

        work_package.save
      end
    end

    before do
      def self.change_custom_field_value(work_package, value)
        val = custom_field.custom_options.find { |co| co.value == value }.try(:id)

        work_package.custom_field_values = { custom_field.id => (val || value) }
        work_package.save
      end
    end

    shared_examples_for 'work package with required custom field' do
      subject { work_package.available_custom_fields }

      it { is_expected.to include(custom_field) }
    end

    context 'required custom field exists' do
      include_context 'project with required custom field'

      it_behaves_like 'work package with required custom field'

      describe 'invalid custom field values' do
        context 'short error message' do
          shared_examples_for 'custom field with invalid value' do
            let(:custom_field_key) { "custom_field_#{custom_field.id}".to_sym }

            before do
              change_custom_field_value(work_package, custom_field_value)
            end

            describe 'error message' do
              before do work_package.save end

              subject { work_package.errors[custom_field_key] }

              it {
                is_expected.to include(I18n.translate("activerecord.errors.messages.#{error_key}"))
              }
            end

            describe 'symbols_for' do
              before do
                work_package.save
              end

              it 'stores the symbol' do
                actual_symbols = work_package.errors.symbols_for(custom_field_key)
                expect(actual_symbols).to match_array([error_key.to_sym])
              end
            end

            describe 'work package attribute update' do
              subject { work_package.save }

              it { is_expected.to be_falsey }
            end
          end

          context 'no value given' do
            let(:custom_field_value) { nil }

            it_behaves_like 'custom field with invalid value' do
              let(:error_key) { 'blank' }
            end
          end

          context 'empty value given' do
            let(:custom_field_value) { '' }

            it_behaves_like 'custom field with invalid value' do
              let(:error_key) { 'blank' }
            end
          end

          context 'invalid value given' do
            let(:custom_field_value) { 'SQLServer' }

            it_behaves_like 'custom field with invalid value' do
              let(:error_key) { 'inclusion' }
            end
          end
        end

        context 'full error message' do
          before do change_custom_field_value(work_package, 'SQLServer') end

          subject { work_package.errors.full_messages.first }

          it 'matches' do
            is_expected.to eq("Database #{I18n.t('activerecord.errors.messages.inclusion')}")
          end
        end
      end

      describe 'valid value given' do
        before do change_custom_field_value(work_package, 'PostgreSQL') end

        context 'errors' do
          subject { work_package.errors[:custom_values] }

          it { is_expected.to be_empty }
        end

        context 'save' do
          before do
            work_package.save!
            work_package.reload
          end

          subject { work_package.custom_value_for(custom_field.id).typed_value }

          it { is_expected.to eq('PostgreSQL') }
        end

        describe 'value change' do
          before do
            change_custom_field_value(work_package, 'PostgreSQL')
            @initial_custom_value = work_package.custom_value_for(custom_field).id
            change_custom_field_value(work_package, 'MySQL')

            work_package.reload
          end

          subject { work_package.custom_value_for(custom_field).id }

          it { is_expected.to eq(@initial_custom_value) }
        end
      end
    end

    describe 'work package type change' do
      let (:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }
      let(:type_feature) {
        FactoryGirl.create(:type_feature,
                           custom_fields: [custom_field_2])
      }

      before do
        project.work_package_custom_fields << custom_field_2
        project.types << type_feature
      end

      context 'with initial type' do
        include_context 'project with required custom field'

        describe 'pre-condition' do
          it_behaves_like 'work package with required custom field'
        end

        describe 'does not change custom fields w/o save' do
          before do
            change_custom_field_value(work_package, 'PostgreSQL')
            work_package.reload

            work_package.type = type_feature
          end

          subject { WorkPackage.find(work_package.id).custom_value_for(custom_field).typed_value }

          it { is_expected.to eq('PostgreSQL') }
        end
      end

      context 'w/o initial type' do
        let(:work_package_without_type) {
          FactoryGirl.build_stubbed(:work_package,
                                    project: project,
                                    type: type)
        }

        describe 'pre-condition' do
          subject { work_package_without_type.custom_field_values }

          it { is_expected.to be_empty }
        end

        context 'with assigning type' do
          before do work_package_without_type.type = type_feature end

          subject { work_package_without_type.custom_field_values }

          it { is_expected.not_to be_empty }
        end
      end

      describe 'assign type id first' do
        let(:attribute_hash) { ActiveSupport::OrderedHash.new }

        before do
          attribute_hash['custom_field_values'] = { custom_field_2.id => 'true' }
          attribute_hash['type_id'] = type_feature.id
        end

        subject do
          wp = WorkPackage.new.tap do |i|
            i.attributes = { project: project }
          end
          wp.attributes = attribute_hash

          wp.custom_value_for(custom_field_2.id).value
        end

        it { is_expected.to eql(CustomValue::BoolStrategy::DB_VALUE_TRUE) }
      end
    end

    describe "custom field type 'text'" do
      let(:value) { 'text' * 1024 }
      let(:custom_field) {
        FactoryGirl.create(:work_package_custom_field,
                           name: 'Test Text',
                           field_format: 'text',
                           is_required: true)
      }

      include_context 'project with required custom field'

      it_behaves_like 'work package with required custom field'

      describe 'value' do
        let(:relevant_journal) {
          work_package.journals.find { |j| j.customizable_journals.size > 0 }
        }
        subject { relevant_journal.customizable_journals.first.value }

        before do
          change_custom_field_value(work_package, value)
        end

        it { is_expected.to eq(value) }
      end
    end

    describe 'validation error interpolation' do
      let :custom_field do
        FactoryGirl.create :work_package_custom_field,
                           name: 'PIN',
                           field_format: 'text',
                           max_length: 4,
                           is_required: true
      end

      include_context 'project with required custom field'

      it 'works for the max length validation' do
        work_package.custom_field_values.first.value = '12345'

        # don't want to see I18n::MissingInterpolationArgument specifically
        expect { work_package.valid? }.not_to raise_error
        expect(work_package.valid?).to be_falsey

        expect(work_package.errors.full_messages.first)
          .to eq ('PIN is too long (maximum is 4 characters).')
      end
    end
  end
end
