# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Announcement do
  it do
    expect(subject).to respond_to :text
  end

  it do
    expect(subject).to respond_to :text=
  end

  it do
    expect(subject).to respond_to :show_until
  end

  it do
    expect(subject).to respond_to :show_until=
  end

  it do
    expect(subject).to respond_to :active?
  end

  it do
    expect(subject).to respond_to :active=
  end

  describe "class methods" do
    describe "#only_one" do
      context "WHEN no announcement exists" do
        it do
          expect(Announcement.only_one.text).to eql "Announcement"
        end

        it do
          expect(Announcement.only_one.show_until).to eql(Date.today + 14.days)
        end

        it { expect(Announcement.only_one.active).to be false }
      end

      context "WHEN an announcement exists" do
        let!(:announcement) { create(:announcement) }

        it "returns the true one announcement" do
          expect(Announcement.only_one).to eql announcement
        end
      end
    end

    describe "#active_and_current" do
      describe "WHEN no announcement is active" do
        let!(:announcement) { create(:inactive_announcement) }

        it "returns no announcement" do
          expect(Announcement.active_and_current).to be_nil
        end
      end

      describe "WHEN the one announcement is active and today is before show_until" do
        let!(:announcement) do
          create(:active_announcement, show_until: Date.today + 14.days)
        end

        it "returns that announcement" do
          expect(Announcement.active_and_current).to eql announcement
        end
      end

      describe "WHEN the one announcement is active and today is after show_until" do
        let!(:announcement) do
          create(:active_announcement, show_until: Date.today - 14.days)
        end

        it "returns no announcement" do
          expect(Announcement.active_and_current).to be_nil
        end
      end

      describe "WHEN the one announcement is active and today equals show_until" do
        let!(:announcement) do
          create(:active_announcement, show_until: Date.today)
        end

        it "returns that announcement" do
          expect(Announcement.active_and_current).to eql announcement
        end
      end
    end

    describe "instance methods" do
      describe "#active_and_current?" do
        describe "WHEN the announcement is not active" do
          let(:announcement) { build(:inactive_announcement) }

          it { expect(announcement.active_and_current?).to be_falsey }
        end

        describe "WHEN the announcement is active and today is before show_until" do
          let(:announcement) do
            build(:active_announcement, show_until: Date.today + 14.days)
          end

          it { expect(announcement.active_and_current?).to be_truthy }
        end

        describe "WHEN the announcement is active and today is after show_until" do
          let!(:announcement) do
            create(:active_announcement, show_until: Date.today - 14.days)
          end

          it { expect(announcement.active_and_current?).to be_falsey }
        end

        describe "WHEN the announcement is active and today equals show_until" do
          let!(:announcement) do
            build(:active_announcement, show_until: Date.today)
          end

          it { expect(announcement.active_and_current?).to be_truthy }
        end
      end
    end
  end
end
