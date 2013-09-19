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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe '/api/v2/projects/index.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with no project available' do
    it 'renders an empty projects document' do
      assign(:projects, [])

      render

      response.should have_selector('projects', :count => 1)
      response.should have_selector('projects[type=array][size="0"]') do
        without_tag 'project'
      end
    end
  end


  describe 'with some projects available' do
    let(:projects) {
      [
        FactoryGirl.build(:project, :name => 'P1'),
        FactoryGirl.build(:project, :name => 'P2'),
        FactoryGirl.build(:project, :name => 'P3')
      ]
    }

    it 'renders a projects document with the size of 3 of type array' do
      assign(:projects, projects)

      render

      response.should have_selector('projects', :count => 1)
      response.should have_selector('projects[type=array][size="3"]')
    end

    it 'renders a project for each assigned project' do
      assign(:projects, projects)

      render

      response.should have_selector('projects project', :count => 3)
    end

    it 'renders the _project template for each assigned project' do
      assign(:projects, projects)

      view.should_receive(:render).exactly(3).times.with(hash_including(:partial => '/api/v2/projects/project.api')).and_return('')

      # just to call the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({ :template=>"/api/v2/projects/index", :handlers=>["rsb"], :formats=>["api"] }, {}).and_call_original

      render
    end

    it 'passes the projects as local var to the partial' do
      assign(:projects, projects)

      view.should_receive(:render).once.with(hash_including(:object => projects.first)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => projects.second)).and_return('')
      view.should_receive(:render).once.with(hash_including(:object => projects.third)).and_return('')

      # just to call the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({ :template=>"/api/v2/projects/index", :handlers=>["rsb"], :formats=>["api"] }, {}).and_call_original

      render
    end
  end
end
