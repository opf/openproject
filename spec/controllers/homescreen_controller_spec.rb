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

describe HomescreenController, type: :controller do
  before do
    allow(User).to receive(:current).and_return(user)

    # assume anonymous may access the page
    allow(Setting).to receive(:login_required?).and_return(false)
    get :index
  end

  let(:all_blocks) {
    %w(administration community my_account projects users)
  }

  shared_examples 'renders blocks' do
    it 'renders a response' do
      expect(response.status).to eq(200)
    end

    describe 'with rendered views' do
      render_views

      it 'renders the given blocks' do
        shown.each do |block|
          expect(response).to render_template(partial: "homescreen/blocks/_#{block}")
        end
      end

      it 'does not render the other blocks' do
        (all_blocks - shown).each do |block|
          expect(response).not_to render_template(partial: "homescreen/blocks/_#{block}")
        end
      end
    end
  end

  context 'with admin' do
    let(:user) { FactoryGirl.build(:admin) }
    it_behaves_like 'renders blocks' do
      let(:shown) { all_blocks }
    end
  end

  context 'regular user' do
    let(:user) { FactoryGirl.build(:user) }
    it_behaves_like 'renders blocks' do
      let(:shown) { all_blocks - %w(administration users) }
    end
  end

  context 'anonymous user' do
    let(:user) { User.anonymous }
    it_behaves_like 'renders blocks' do
      let(:shown) { all_blocks - %w(administration users my_account) }
    end
  end
end
