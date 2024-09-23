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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Activities::ItemSubtitleComponent, type: :component do
  include Redmine::I18n

  let(:datetime) { Time.current }

  subject { render_inline(described_class.new(user:, datetime:, is_creation:, is_deletion:, is_work_package:, journable_type:)) }

  context "on creation with a user" do
    let(:is_creation) { true }
    let(:user) { build_stubbed(:user) }
    let(:journable_type) { "WorkPackage" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("created by  #{user.name} on #{format_time(datetime)}") }
  end

  context "on creation without a user" do
    let(:is_creation) { true }
    let(:user) { nil }
    let(:journable_type) { "WorkPackage" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("created on #{format_time(datetime)}") }
  end

  context "on update with a user" do
    let(:is_creation) { false }
    let(:user) { build_stubbed(:user) }
    let(:journable_type) { "WorkPackage" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("updated by  #{user.name} on #{format_time(datetime)}") }
  end

  context "on update without a user" do
    let(:is_creation) { false }
    let(:user) { nil }
    let(:journable_type) { "WorkPackage" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("updated on #{format_time(datetime)}") }
  end

  context "on delete with a user" do
    let(:is_creation) { false }
    let(:user) { build_stubbed(:user) }
    let(:journable_type) { "Meeting" }
    let(:is_deletion) { true }
    let(:is_work_package) { false }

    it { is_expected.to have_text("deleted by  #{user.name} on #{format_time(datetime)}") }
  end

  context "on delete without a user" do
    let(:is_creation) { false }
    let(:user) { nil }
    let(:journable_type) { "Meeting" }
    let(:is_deletion) { true }
    let(:is_work_package) { false }

    it { is_expected.to have_text("deleted on #{format_time(datetime)}") }
  end

  context "on TimeEntry creation" do
    let(:is_creation) { true }
    let(:user) { build_stubbed(:user) }
    let(:journable_type) { "TimeEntry" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("time logged by  #{user.name} on #{format_time(datetime)}") }
  end

  context "on TimeEntry updation" do
    let(:is_creation) { false }
    let(:user) { build_stubbed(:user) }
    let(:journable_type) { "TimeEntry" }
    let(:is_deletion) { false }
    let(:is_work_package) { false }

    it { is_expected.to have_text("logged time updated by  #{user.name} on #{format_time(datetime)}") }
  end
end
