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
#++

require 'spec_helper'

describe ::API::V3::WorkPackages::Form::WorkPackagePayloadRepresenter do
  let(:work_package) {
    FactoryGirl.build(:work_package,
                      created_at: DateTime.now,
                      updated_at: DateTime.now)
  }
  let(:representer)  { described_class.new(work_package) }

  before { allow(work_package).to receive(:lock_version).and_return(1) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { is_expected.to have_json_path('subject') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'textile' }
        let(:raw) { work_package.description }
        let(:html) { '<p>' + work_package.description + '</p>' }
      end

      describe 'lock version' do
        it { is_expected.to have_json_path('lockVersion') }

        it { is_expected.to have_json_type(Integer).at_path('lockVersion') }

        it { is_expected.to be_json_eql(work_package.lock_version.to_json).at_path('lockVersion') }
      end
    end

    describe '_links' do
      it { is_expected.to have_json_path('_links') }

      let(:path) { "_links/#{property}/href" }

      shared_examples_for 'linked property' do
        before do
          unless defined?(link) && defined?(property)
            raise "Requires to have 'property' and 'link' defined"
          end
        end

        it { expect(subject).to be_json_eql(link.to_json).at_path(path) }
      end

      describe 'status' do
        let(:status) { FactoryGirl.build_stubbed(:status) }

        before { work_package.status = status }

        it_behaves_like 'linked property' do
          let(:property) { 'status' }
          let(:link) { "/api/v3/statuses/#{status.id}" }
        end
      end

      describe 'assignee and responsible' do
        let(:user) { FactoryGirl.build_stubbed(:user) }
        let(:link) { "/api/v3/users/#{user.id}" }

        describe 'assignee' do
          before { work_package.assigned_to = user }

          it_behaves_like 'linked property' do
            let(:property) { 'assignee' }
          end
        end

        describe 'responsible' do
          before { work_package.responsible = user }

          it_behaves_like 'linked property' do
            let(:property) { 'responsible' }
          end
        end
      end

      describe 'version' do
        let(:version) { FactoryGirl.build_stubbed(:version) }

        before { work_package.fixed_version = version }

        it_behaves_like 'linked property' do
          let(:property) { 'version' }
          let(:link) { "/api/v3/versions/#{version.id}" }
        end
      end
    end
  end
end
