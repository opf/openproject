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
#++

require 'spec_helper'

##
# Tests that email notifications will be sent upon creating or changing a work package.
describe WorkPackage, type: :model do
  describe 'email notifications' do
    let(:user) { FactoryGirl.create :admin }
    let!(:work_package) do
      FactoryGirl.create :work_package,
                         author: user,
                         subject: 'I can see you'
    end

    context 'after creation' do
      it "are sent to the work package's author" do
        mail = ActionMailer::Base.deliveries.detect { |m| m.subject.include? 'I can see you' }

        expect(mail).to be_present
      end
    end

    describe 'after update' do
      before do
        work_package.update_attributes subject: 'the wind of change'
      end

      it "are sent to the work package's author" do
        mail = ActionMailer::Base.deliveries.detect { |m| m.subject.include? 'the wind of change' }

        expect(mail).to be_present
      end
    end
  end
end
