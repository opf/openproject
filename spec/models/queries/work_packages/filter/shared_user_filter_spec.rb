# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe Queries::WorkPackages::Filter::SharedUserFilter do
  create_shared_association_defaults_for_work_package_factory

  describe 'where filter results' do
    shared_let(:shared_with_user) { create(:user) }

    shared_let(:non_shared_work_package) { create(:work_package) }

    shared_let(:shared_work_package) { create(:work_package) }
    shared_let(:work_package_role) { create(:work_package_role, permissions: %i[blurgh]) }
    shared_let(:work_package_membership) do
      create(:member,
             user: shared_with_user,
             project: project_with_types,
             entity: shared_work_package,
             roles: [work_package_role])
    end

    let(:instance) do
      described_class.create!.tap do |filter|
        filter.values = values
        filter.operator = operator
      end
    end

    subject { WorkPackage.where(instance.where) }

    context 'with a "=" operator' do
      let(:operator) { '=' }

      context 'for a user value' do
        before do
          login_as(user)
        end

        let(:values) { [shared_with_user.id.to_s] }

        it 'returns the shared work package' do
          expect(subject)
            .to contain_exactly(shared_work_package)
        end
      end

      context 'for a list of users where at least one was shared a work package' do
        before do
          login_as(user)
        end

        let(:values) { [shared_with_user.id.to_s, user.id.to_s] }

        it 'returns the shared work package' do
          expect(subject)
            .to contain_exactly(shared_work_package)
        end
      end

      context 'for the "me" value' do
        let(:values) { %w[me] }

        context "when I'm the shared with user" do
          before do
            login_as(shared_with_user)
          end

          it 'returns the shared work package' do
            expect(subject)
              .to contain_exactly(shared_work_package)
          end
        end

        context "when I'm not the shared with user" do
          before do
            login_as(user)
          end

          it 'does not return the any work packages' do
            expect(subject)
              .to be_empty
          end
        end
      end
    end

    context 'with a "!" operator' do
      let(:operator) { '!' }

      context 'for a user value' do
        before do
          login_as(user)
        end

        let(:values) { [shared_with_user.id.to_s] }

        it 'returns the non-shared work package' do
          expect(subject)
            .to contain_exactly(non_shared_work_package)
        end
      end

      context 'for the "me" value' do
        let(:values) { %w[me] }

        context "when I'm the shared with user" do
          before do
            login_as(shared_with_user)
          end

          it 'returns the non-shared work package' do
            expect(subject)
              .to contain_exactly(non_shared_work_package)
          end
        end

        context "when I'm not the shared with user" do
          before do
            login_as(user)
          end

          it 'returns all work packages' do
            expect(subject)
              .to contain_exactly(shared_work_package,
                                  non_shared_work_package)
          end
        end
      end
    end

    context 'with a "*" operator' do
      before do
        login_as(user)
      end

      let(:operator) { '*' }
      let(:values) { [] }

      it 'returns the shared work package' do
        expect(subject)
          .to contain_exactly(shared_work_package)
      end
    end

    context 'with a "!*" operator' do
      before do
        login_as(user)
      end

      let(:operator) { '!*' }
      let(:values) { [] }

      it 'returns the non-shared work package' do
        expect(subject)
          .to contain_exactly(non_shared_work_package)
      end
    end
  end

  it_behaves_like 'basic query filter' do
    let(:type) { :shared_user_list_optional }
    let(:class_key) { :shared_user }
    let(:human_name) { I18n.t('query_fields.shared_with_user') }

    describe '#available?' do
      context "when I'm logged in" do
        before do
          login_as user
        end

        context "and I have the necessary permissions" do
          before do
            allow(user)
              .to receive(:allowed_to?)
                    .with(:view_shared_work_packages, nil, global: true)
                    .and_return(true)
          end

          it do
            expect(instance).to be_available
          end
        end

        context "and I don't have the necessary permissions" do
          before do
            allow(user)
              .to receive(:allowed_to?)
                    .with(:view_shared_work_packages, nil, global: true)
                    .and_return(false)
          end

          it { expect(instance).not_to be_available }
        end
      end

      context "when I'm not logged in" do
        it { expect(instance).not_to be_available }
      end
    end
  end
end
