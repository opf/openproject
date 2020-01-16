#-- encoding: UTF-8

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

describe Projects::SetAttributesService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    contract = double('contract_class')

    allow(contract)
      .to receive(:new)
      .with(project, user, options: { changed_by_system: [] })
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double('contract_instance', validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double('contract_errors')
  end
  let(:project_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        model: project,
                        contract_class: contract_class)
  end
  let(:call_attributes) { {} }
  let(:project) do
    FactoryBot.build_stubbed(:project)
  end

  describe 'call' do
    let(:call_attributes) do
      {
      }
    end

    before do
      allow(project)
        .to receive(:valid?)
        .and_return(project_valid)

      expect(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'sets the attributes' do
      subject

      expect(project.attributes.slice(*project.changed).symbolize_keys)
        .to eql call_attributes
    end

    it 'does not persist the project' do
      expect(project)
        .not_to receive(:save)

      subject
    end

    context 'for a new record' do
      let(:project) do
        Project.new
      end

      context 'identifier default value' do
        context 'with a default identifier configured', with_settings: {sequential_project_identifiers: true} do
          context 'with an identifier provided' do
            let(:call_attributes) do
              {
                identifier: 'lorem'
              }
            end

            it 'does not alter the identifier' do
              expect(subject.result.identifier)
                .to eql 'lorem'
            end
          end

          context 'with no identifier provided' do
            it 'sets a default identifier' do
              allow(Project)
                .to receive(:next_identifier)
                      .and_return('ipsum')

              expect(subject.result.identifier)
                .to eql 'ipsum'
            end
          end
        end

        context 'without a default identifier configured', with_settings: {sequential_project_identifiers: false} do
          context 'with an identifier provided' do
            let(:call_attributes) do
              {
                identifier: 'lorem'
              }
            end

            it 'does not alter the identifier' do
              expect(subject.result.identifier)
                .to eql 'lorem'
            end
          end

          context 'with no identifier provided' do
            it 'stays nil' do
              allow(Project)
                .to receive(:next_identifier)
                      .and_return('ipsum')

              expect(subject.result.identifier)
                .to be_nil
            end
          end
        end
      end

      context 'public default value', with_settings: {default_projects_public: true} do
        context 'with a value for is_public provided' do
          let(:call_attributes) do
            {
              public: false
            }
          end

          it 'does not alter the public value' do
            expect(subject.result)
              .not_to be_public
          end
        end

        context 'with no value for public provided' do
          it 'sets uses the default value' do
            expect(subject.result)
              .to be_public
          end
        end
      end

      context 'enabled_module_names default value', with_settings: {default_projects_modules: ['lorem', 'ipsum']} do
        context 'with a value for enabled_module_names provided' do
          let(:call_attributes) do
            {
              enabled_module_names: %w(some other)
            }
          end

          it 'does not alter the enabled modules' do
            expect(subject.result.enabled_module_names)
              .to match_array %w(some other)
          end
        end

        context 'with no value for enabled_module_names provided' do
          it 'sets a default enabled modules' do
            expect(subject.result.enabled_module_names)
              .to match_array %w(lorem ipsum)
          end
        end

        context 'with the enabled modules being set before' do
          before do
            project.enabled_module_names = %w(some other)
          end

          it 'does not alter the enabled modules' do
            expect(subject.result.enabled_module_names)
              .to match_array %w(some other)
          end
        end
      end

      context 'types default value' do
        let(:other_types) do
          [FactoryBot.build_stubbed(:type)]
        end
        let(:default_types) do
          [FactoryBot.build_stubbed(:type)]
        end
        before do
          allow(Type)
            .to receive(:default)
                  .and_return default_types
        end

        context 'with a value for types provided' do
          let(:call_attributes) do
            {
              types: other_types
            }
          end

          it 'does not alter the types' do
            expect(subject.result.types)
              .to match_array other_types
          end
        end

        context 'with no value for types provided' do
          it 'sets the default types' do
            expect(subject.result.types)
              .to match_array default_types
          end
        end

        context 'with the types being set before' do
          before do
            project.types.build(name: 'lorem')
          end

          it 'does not alter the types modules' do
            expect(subject.result.types.map(&:name))
              .to match_array %w(lorem)
          end
        end
      end

      context 'project status' do
        context 'with a value provided' do
          let(:call_attributes) do
            {
              status: {
                code: 'on_track',
                explanation: 'A magic dwells in each beginning.'
              }
            }
          end

          it 'set the project status code' do
            expect(subject.result.status.code)
              .to eql 'on_track'
          end

          it 'set the project status explanation' do
            expect(subject.result.status.explanation)
              .to eql 'A magic dwells in each beginning.'
          end

          it 'does not persist the status' do
            expect(subject.result.status)
              .to be_new_record
          end
        end
      end
    end

    context 'for an existing project' do
      context 'project status' do
        context 'with the project not having a status before' do
          context 'with a value provided' do
            let(:call_attributes) do
              {
                status: {
                  code: 'on_track',
                  explanation: 'A magic dwells in each beginning.'
                }
              }
            end

            it 'set the project status code' do
              expect(subject.result.status.code)
                .to eql 'on_track'
            end

            it 'set the project status explanation' do
              expect(subject.result.status.explanation)
                .to eql 'A magic dwells in each beginning.'
            end

            it 'does not persist the status' do
              expect(subject.result.status)
                .to be_new_record
            end
          end

          context 'with an invalid code' do
            let(:call_attributes) do
              {
                status: {
                  code: 'bogus',
                  explanation: 'A magic dwells in each beginning.'
                }
              }
            end

            it 'set the project status code' do
              expect(subject.result.status.code)
                .to eql 'bogus'
            end

            it 'set the project status explanation' do
              expect(subject.result.status.explanation)
                .to eql 'A magic dwells in each beginning.'
            end

            it 'does not persist the status' do
              expect(subject.result.status)
                .to be_new_record
            end
          end
        end

        context 'with the project having a status before' do
          let(:project_status) do
            FactoryBot.build_stubbed(:project_status)
          end
          let(:project) do
            FactoryBot.build_stubbed(:project, status: project_status)
          end

          context 'with a value provided' do
            let(:call_attributes) do
              {
                status: {
                  code: 'at_risk',
                  explanation: 'Still some magic there.'
                }
              }
            end

            it 'set the project status code' do
              expect(subject.result.status.code)
                .to eql 'at_risk'
            end

            it 'set the project status explanation' do
              expect(subject.result.status.explanation)
                .to eql 'Still some magic there.'
            end

            it 'does not persist the status' do
              expect(subject.result.status)
                .to be_changed
            end
          end
        end
      end
    end
  end
end
