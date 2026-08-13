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

require "spec_helper"

RSpec.describe JournalFormatter::Base do
  let(:work_package) { build_stubbed(:work_package) }
  let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }
  let(:instance) { described_class.new(journal) }
  let(:key) { "name" }

  # JournalFormatter#render_detail calls this before #render for every formatter
  # (see spec/models/journal_spec.rb), so the formatters themselves no longer
  # check it in their own #render methods. The denied-message rendering itself
  # has no per-formatter behavior, so it lives directly on JournalFormatter#render_detail
  # (see spec/models/journal_spec.rb) rather than on individual formatters.
  describe "#permission_granted?" do
    subject { instance.permission_granted?(permission, key:) }

    context "without a permission" do
      let(:permission) { nil }

      it { is_expected.to be(true) }
    end

    context "with a Proc permission" do
      context "when the proc allows" do
        let(:permission) { -> { true } }

        it { is_expected.to be(true) }
      end

      context "when the proc denies" do
        let(:permission) { -> { false } }

        it { is_expected.to be(false) }
      end

      it "is instance_exec'd against the formatter" do
        permission = proc { self }

        expect(instance.permission_granted?(permission, key:)).to be(instance)
      end
    end

    context "with a named (Symbol) permission" do
      let(:permission) { :view_work_packages }
      let(:project) { build_stubbed(:project) }
      let(:work_package) { build_stubbed(:work_package, project:) }

      context "when the current user has the permission in the project" do
        before do
          allow(User.current).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(true)
        end

        it { is_expected.to be(true) }
      end

      context "when the current user lacks the permission in the project" do
        before do
          allow(User.current).to receive(:allowed_in_project?).with(:view_work_packages, project).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
