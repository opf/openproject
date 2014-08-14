#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe ::API::V3::Users::UserRepresenter do
  let(:user)             { FactoryGirl.build_stubbed(:user,
                                                     created_on: Time.now,
                                                     updated_on: Time.now) }
  let(:model)          { ::API::V3::Users::UserModel.new(user) }
  let(:representer) { described_class.new(model) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('User'.to_json).at_path('_type') }

    describe 'user' do
      it { is_expected.to have_json_path('id')   }
      it { is_expected.to have_json_path('login') }
      it { is_expected.to have_json_path('firstName') }
      it { is_expected.to have_json_path('lastName') }
      it { is_expected.to have_json_path('name') }
      it { is_expected.to have_json_path('mail') }
      it { is_expected.to have_json_path('avatar') }
      it { is_expected.to have_json_path('createdAt') }
      it { is_expected.to have_json_path('updatedAt') }
      it { is_expected.to have_json_path('status') }
      it { is_expected.to have_json_path('avatar') }
    end

    describe '_links' do
      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
      end
    end

    describe 'avatar' do
      before do
        user.mail = 'foo@bar.com'
        Setting.stub(:gravatar_enabled?).and_return(true)
      end

      it 'should have an url to gravatar if settings permit and mail is set' do
        expect(parse_json(subject, 'avatar')).to start_with('http://gravatar.com/avatar')
      end

      it 'should be blank if gravatar is disabled' do
        Setting.stub(:gravatar_enabled?).and_return(false)

        expect(parse_json(subject, 'avatar')).to be_blank
      end

      it 'should be blank if email is missing (e.g. anonymous)' do
        user.mail = nil

        expect(parse_json(subject, 'avatar')).to be_blank
      end

      it 'should be https if setting set to https' do
        # have to actually set the setting for the lib to pick up the change
        with_settings protocol: 'https' do
          expect(parse_json(subject, 'avatar')).to start_with('https://secure.gravatar.com/avatar')
        end
      end
    end
  end
end
