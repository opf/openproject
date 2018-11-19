#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe Grids::SetAttributesService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:new_grid) do
    wp = Grid.new

    allow(wp)
      .to receive(:valid?)
      .and_return(grid_valid)

    wp
  end
  let(:mock_contract) do
    double(contract_class,
           new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    mock = mock_model(contract_class)
    allow(mock)
      .to receive(:validate)
      .and_return contract_valid

    mock
  end
  let(:contract_valid) { true }
  let(:grid_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        grid: work_package,
                        contract_class: mock_contract)
  end
  let(:call_attributes) { {} }

  describe 'call' do
    shared_examples_for 'service call' do
      subject { instance.call(call_attributes) }

      it 'is successful' do
        expect(subject.success?).to be_truthy
      end

      it 'sets the value' do
        subject

        attributes.each do |attribute, key|
          expect(work_package.send(attribute)).to eql key
        end
      end

      it 'does not persist the grid' do
        expect(grid)
          .not_to receive(:save)

        subject
      end

      it 'has no errors' do
        expect(subject.errors).to be_empty
      end

      context 'when the contract does not validate' do
        let(:contract_valid) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'does not persist the changes' do
          expect(grid)
            .to_not receive(:save)

          subject
        end

        it "exposes the contract's errors" do
          subject

          expect(subject.errors).to eql mock_contract_instance.errors
        end
      end

      context 'when the grid is invalid' do
        let(:grid) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'leaves the value unchanged' do
          subject

          expect(grid.changed?).to be_truthy
        end

        it "exposes the grid's errors" do
          subject

          expect(subject.errors).to eql grid.errors
        end
      end
    end

    context 'on a new grid' do
      context 'without parameters' do

      end
    end

    context 'status' do
      let(:default_status) { FactoryBot.build_stubbed(:default_status) }
      let(:other_status) { FactoryBot.build_stubbed(:status) }
      let(:new_statuses) { [other_status, default_status] }

      before do
        allow(work_package)
          .to receive(:new_statuses_allowed_to)
                .with(user, true)
                .and_return(new_statuses)
        allow(Status)
          .to receive(:default)
                .and_return(default_status)
      end

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.status = nil
        end

        it_behaves_like 'service call' do
          it 'sets the default status' do
            subject

            expect(work_package.status)
              .to eql default_status
          end
        end
      end

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.status = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.status)
              .to be_nil
          end
        end
      end

      context 'update status before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { status: other_status } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating status via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { status: other_status } }

        it_behaves_like 'service call'
      end
    end

    context 'author' do
      let(:other_user) { FactoryBot.build_stubbed(:user) }

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.author = nil
        end

        it_behaves_like 'service call' do
          it "sets the service's author" do
            subject

            expect(work_package.author)
              .to eql user
          end
        end
      end

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.author = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.author)
              .to be_nil
          end
        end
      end

      context 'update author before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { author: other_user } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating author via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { author: other_user } }

        it_behaves_like 'service call'
      end
    end

    context 'with the actual contract' do
      let(:invalid_wp) do
        wp = FactoryBot.create(:work_package)
        wp.start_date = Date.today + 5.days
        wp.due_date = Date.today
        wp.save!(validate: false)

        wp
      end
      let(:user) { FactoryBot.build_stubbed(:admin) }
      let(:instance) do
        described_class.new(user: user,
                            work_package: invalid_wp,
                            contract_class: contract_class)
      end

      context 'with a current invalid start date' do
        let(:call_attributes) { attributes }
        let(:attributes) { { start_date: Date.today - 5.days } }
        let(:contract_valid) { true }
        let(:work_package_valid) { true }
        subject { instance.call(call_attributes) }

        it 'is successful' do
          expect(subject.success?).to be_truthy
          expect(subject.errors).to be_empty
        end
      end
    end

    context 'priority' do
      let(:default_priority) { FactoryBot.build_stubbed(:priority) }
      let(:other_priority) { FactoryBot.build_stubbed(:priority) }

      before do
        allow(IssuePriority)
          .to receive_message_chain(:active, :default)
                .and_return(default_priority)
      end

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.priority = nil
        end

        it_behaves_like 'service call' do
          it "sets the default priority" do
            subject

            expect(work_package.priority)
              .to eql default_priority
          end
        end
      end

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.priority = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.priority)
              .to be_nil
          end
        end
      end

      context 'update priority before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { priority: other_priority } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating priority via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { priority: other_priority } }

        it_behaves_like 'service call'
      end
    end
  end
end
