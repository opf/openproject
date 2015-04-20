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

describe 'attachments', type: :feature do
  let(:project) { FactoryGirl.create :valid_project }
  let(:current_user) { FactoryGirl.create :admin }
  let!(:priority) { FactoryGirl.create :priority_normal }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'upload', js: true do
    let(:file) { FactoryGirl.create :file, name: 'textfile.txt' }

    it 'uploading a short text file and viewing it inline' do
      visit new_project_work_package_path(project)

      select project.types.first.name, from: "work_package_type_id"
      fill_in 'Subject', with: 'attachment test'

      # open attachment fieldset and attach file
      attach_file 'attachments[1][file]', file.path

      click_button 'Create'

      file_name = File.basename file.path

      expect(page).to have_text('Successful creation.')
      expect(page).to have_text(file_name)

      click_link file_name

      expect(page).to have_text('some silly content')
    end
  end
end
