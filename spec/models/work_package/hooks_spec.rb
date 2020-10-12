#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  describe "#create" do
    it "calls the create hook" do
      subject = "A new work package"

      expect(Redmine::Hook).to receive(:call_hook) do |hook, context|
        expect(hook).to eq :work_package_after_create
        expect(context[:work_package].subject).to eq subject
      end

      FactoryBot.create :work_package, subject: subject
    end
  end

  describe "#update" do
    let!(:work_package) { FactoryBot.create :work_package }

    it "calls the update hook" do
      expect(Redmine::Hook).to receive(:call_hook) do |hook, context|
        expect(hook).to eq :work_package_after_update
        expect(context[:work_package]).to eq work_package
        expect(context[:work_package].journals.last.details[:description].last).to eq "changed description"
      end

      work_package.description = "changed description"
      work_package.save!
    end
  end
end
