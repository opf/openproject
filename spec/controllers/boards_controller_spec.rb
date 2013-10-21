#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe BoardsController do
  let(:user) { FactoryGirl.build(:user) }
  let(:board) { FactoryGirl.build(:board, :project => project) }
  let(:project) { FactoryGirl.build(:project) }

  before do
    disable_flash_sweep
  end

  describe :create do
    let(:params) { { :board => 'blubs_params' } }

    before do
      @controller.should_receive(:authorize)
      @controller.should_receive(:find_project_by_project_id) do
        @controller.instance_variable_set(:@project, project)
      end

      # this line is here for reasons I don't understand
      # without the line the should_receive statement for Board will fail
      board

      Board.should_receive(:new).with(params[:board]).and_return(board)
    end

    describe 'w/ the params beeing valid' do

      before do
        board.should_receive(:save).and_return(true)

        as_logged_in_user user do
          post :create, params
        end
      end

      it 'should redirect to the settings page if successful' do
        response.should redirect_to :controller => '/projects', :action => 'settings', :id => project, :tab => 'boards'
      end

      it 'have a successful creation flash' do
        flash[:notice].should == I18n.t(:notice_successful_create)
      end
    end

    describe 'w/ the params beeing invalid' do

      before do
        board.should_receive(:save).and_return(false)

        as_logged_in_user user do
          post :create, params
        end
      end

      it 'should redirect to the settings page if successful' do
        response.should render_template('new')
      end
    end
  end
end
