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

describe CopyProjectJob do

  let(:user) { FactoryGirl.create(:admin, language: :de) }
  let(:source_project) { FactoryGirl.create(:project) }
  let(:target_project) { FactoryGirl.create(:project) }

  let(:copy_job) { CopyProjectJob.new user,
                                      source_project,
                                      target_project,
                                      [], # enabled modules
                                      [], # associations
                                      false } # send mails

  describe 'copy localizes error message' do
    before do
      # 'Delayed Job' uses a work around to get Rails 3 mailers working with it
      # (see https://github.com/collectiveidea/delayed_job#rails-3-mailers).
      # Thus, we need to return a message object here, otherwise 'Delayed Job'
      # will complain about an object without a method #deliver.
      allow(UserMailer).to receive(:copy_project_failed).and_return(double("Mail::Message", deliver: true))
    end

    it 'sets locale correctly' do
      expect(copy_job).to receive(:create_project_copy) do |*args|
        expect(I18n.locale).to eq(:de)
        [nil, nil]
      end

      copy_job.perform
    end
  end
end
