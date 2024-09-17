#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++
require "spec_helper"

RSpec.describe Journal do
  describe "#journable" do
    it "raises no error on a new journal without a journable" do
      expect(Journal.new.journable)
        .to be_nil
    end
  end

  describe "#notifications" do
    let(:work_package) { create(:work_package) }
    let(:journal) { work_package.journals.first }
    let!(:notification) do
      create(:notification,
             journal:,
             resource: work_package)
    end

    it "has a notifications association" do
      expect(journal.notifications)
        .to contain_exactly(notification)
    end

    it "destroys the associated notifications upon journal destruction" do
      expect { journal.destroy }
        .to change(Notification, :count).from(1).to(0)
    end
  end

  describe "#create" do
    context "without a data foreign key" do
      subject { create(:work_package_journal, data: nil) }

      it "raises an error and does not create a database record" do
        expect { subject }
          .to raise_error(ActiveRecord::NotNullViolation)

        expect(described_class.count)
          .to eq 0
      end
    end
  end
end
