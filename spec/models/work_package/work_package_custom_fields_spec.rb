#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  describe '#custom_fields' do
    let(:type) { FactoryBot.create(:type_standard) }
    let(:project) { FactoryBot.create(:project, types: [type]) }
    let(:work_package) do
      FactoryBot.build(:work_package,
                       project: project,
                       type: type)
    end
    let(:custom_field) do
      FactoryBot.create(:work_package_custom_field,
                        name: 'Database',
                        field_format: 'list',
                        possible_values: %w(MySQL PostgreSQL Oracle),
                        is_required: cf_required)
    end

    let(:cf_required) { true }

    shared_context 'project with custom field' do
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

    context 'touch on save' do
      include_context 'project with custom field'
      let(:cf_required) { false }

      before do
        work_package.update_columns(updated_at: 3.days.ago)
      end

      context 'creating a cf value' do
        it 'updates the updated_at attribute' do
          expect { change_custom_field_value(work_package, custom_field.possible_values.first) }
            .to change { work_package.updated_at }
        end

        it 'updates the lock_version attribute' do
          expect { change_custom_field_value(work_package, custom_field.possible_values.first) }
            .to change { work_package.lock_version }.by(1)
        end
      end

      context 'deleting a cf value' do
        before do
          change_custom_field_value(work_package, custom_field.possible_values.first)
        end

        it 'updates the updated_at attribute' do
          expect { change_custom_field_value(work_package, nil) }
            .to change { work_package.updated_at }
        end

        it 'updates the lock_version attribute' do
          expect { change_custom_field_value(work_package, nil) }
            .to change { work_package.lock_version }.by(1)
        end
      end

      context 'updating a cf value' do
        before do
          change_custom_field_value(work_package, custom_field.possible_values.first)
        end

        it 'updates the updated_at attribute' do
          expect { change_custom_field_value(work_package, custom_field.possible_values.last) }
            .to change { work_package.updated_at }
        end

        it 'updates the lock_version attribute' do
          expect { change_custom_field_value(work_package, custom_field.possible_values.last) }
            .to change { work_package.lock_version }.by(1)
        end
      end

      context 'updating a cf value and another attribute at the same time' do
        before do
          change_custom_field_value(work_package, custom_field.possible_values.first)
        end

        it 'updates the lock_version attribute by 1' do
          work_package.subject = 'new subject'

          expect { change_custom_field_value(work_package, custom_field.possible_values.last) }
            .to change { work_package.lock_version }.by(1)
        end
      end
    end

    context 'required custom field exists' do
      include_context 'project with custom field'

      it_behaves_like 'work package with required custom field'

      describe 'invalid custom field values' do
        context 'short error message' do
          shared_examples_for 'custom field with invalid value' do
            let(:custom_field_key) { "custom_field_#{custom_field.id}".to_sym }

            before do
              change_custom_field_value(work_package, custom_field_value)
            end

            describe 'error message' do
              before { work_package.save }

              subject { work_package.errors[custom_field_key] }

              it {
                is_expected.to include(I18n.t("activerecord.errors.messages.#{error_key}"))
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
          before { change_custom_field_value(work_package, 'SQLServer') }

          subject { work_package.errors.full_messages.first }

          it 'matches' do
            is_expected.to eq("Database #{I18n.t('activerecord.errors.messages.inclusion')}")
          end
        end
      end

      describe 'valid value given' do
        before { change_custom_field_value(work_package, 'PostgreSQL') }

        context 'errors' do
          subject { work_package.errors[:custom_values] }

          it { is_expected.to be_empty }
        end

        context 'save' do
          before do
            work_package.save!
            work_package.reload
          end

          subject { work_package.typed_custom_value_for(custom_field.id) }
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
      let (:custom_field_2) { FactoryBot.create(:work_package_custom_field) }
      let(:type_feature) do
        FactoryBot.create(:type_feature,
                          custom_fields: [custom_field_2])
      end

      before do
        project.work_package_custom_fields << custom_field_2
        project.types << type_feature
      end

      context 'with initial type' do
        include_context 'project with custom field'

        describe 'pre-condition' do
          it_behaves_like 'work package with required custom field'
        end

        describe 'does not change custom fields w/o save' do
          before do
            change_custom_field_value(work_package, 'PostgreSQL')
            work_package.reload

            work_package.type = type_feature
          end

          subject { WorkPackage.find(work_package.id).typed_custom_value_for(custom_field) }
          it { is_expected.to eq('PostgreSQL') }
        end
      end

      context 'w/o initial type' do
        let(:work_package_without_type) do
          FactoryBot.build_stubbed(:work_package,
                                   project: project,
                                   type: type)
        end

        describe 'pre-condition' do
          subject { work_package_without_type.custom_field_values }

          it { is_expected.to be_empty }
        end

        context 'with assigning type' do
          before { work_package_without_type.type = type_feature }

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

        it { is_expected.to eql(OpenProject::Database::DB_VALUE_TRUE) }
      end
    end

    describe "custom field type 'text'" do
      let(:value) { 'text' * 1024 }
      let(:custom_field) do
        FactoryBot.create(:work_package_custom_field,
                          name: 'Test Text',
                          field_format: 'text',
                          is_required: true)
      end

      include_context 'project with custom field'

      it_behaves_like 'work package with required custom field'

      describe 'value' do
        let(:relevant_journal) do
          work_package.journals.find { |j| j.customizable_journals.size > 0 }
        end
        subject { relevant_journal.customizable_journals.first.value }

        before do
          change_custom_field_value(work_package, value)
        end

        it { is_expected.to eq(value) }
      end
    end

    describe 'validation error interpolation' do
      let :custom_field do
        FactoryBot.create :work_package_custom_field,
                          name: 'PIN',
                          field_format: 'text',
                          max_length: 4,
                          is_required: true
      end

      include_context 'project with custom field'

      it 'works for the max length validation' do
        work_package.custom_field_values.first.value = '12345'

        # don't want to see I18n::MissingInterpolationArgument specifically
        expect { work_package.valid? }.not_to raise_error
        expect(work_package.valid?).to be_falsey

        expect(work_package.errors.full_messages.first)
          .to eq 'PIN is too long (maximum is 4 characters).'
      end
    end
  end
end
