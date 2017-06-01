#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.

require 'spec_helper'

describe Users::UpdateUserService do
  let(:current_user) { FactoryGirl.build_stubbed(:admin) }
  let(:update_user) { FactoryGirl.build_stubbed(:user) }
  let(:instance) { described_class.new(user: update_user, current_user: current_user) }

  describe '.contract' do
    it 'uses the UpdateContract contract' do
      expect(described_class.contract).to eql Users::UpdateContract
    end
  end

  describe '.new' do
    it 'takes a user which is available as a getter' do
      expect(instance.current_user).to eql current_user
    end
  end

  describe 'updating attributes' do
    let(:update_user) { FactoryGirl.create(:user, mail: 'correct@example.org') }
    subject { instance.call(attributes: attributes) }

    context 'when invalid' do
      let(:attributes) { { mail: 'invalid' } }

      it 'fails to update' do
        expect(subject).to_not be_success

        update_user.reload
        expect(update_user.mail).to eq('correct@example.org')

        expect(subject.errors.symbols_for(:mail)).to match_array(%i[invalid])
      end
    end

    context 'when valid' do
      let(:attributes) { { mail: 'new@example.org' } }

      it 'updates the user' do
        expect(subject).to be_success

        update_user.reload
        expect(update_user.mail).to eq('new@example.org')
      end

      context 'if current_user is no admin' do
        let(:current_user) { FactoryGirl.build_stubbed(:user) }
        it 'is unsuccessful' do
          expect(subject).to_not be_success
        end
      end
    end
  end

  describe '#call' do
    subject { instance.call() }
    let(:validates) { true }
    let(:saves) { true }

    before do
      allow(update_user).to receive(:save).and_return(saves)
      allow_any_instance_of(Users::UpdateContract).to receive(:validate).and_return(validates)
    end

    context 'if contract validates and the user saves' do
      it 'is successful' do
        expect(subject).to be_success
      end

      it 'has no errors' do
        expect(subject.errors).to be_empty
      end

      it 'returns the user as a result' do
        result = subject.result
        expect(result).to be_a User
      end
    end

    context 'if contract does not validate' do
      let(:validates) { false }

      it 'is unsuccessful' do
        expect(subject).to_not be_success
      end
    end

    context 'if user does not save' do
      let(:saves) { false }
      let(:errors) { double('errors') }

      it 'is unsuccessful' do
        expect(subject).to_not be_success
      end

      it "returns the user's errors" do
        allow(update_user)
          .to receive(:errors)
          .and_return errors

        expect(subject.errors).to eql errors
      end
    end
  end
end
