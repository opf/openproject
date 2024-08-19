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

RSpec.describe Members::RoleFormComponent, type: :component do
  subject { described_class.new(member, row:, params:, roles:) }

  let(:principal) { build_stubbed(:principal, id: 42) }
  let(:project) { build_stubbed(:project) }
  let(:roles) { build_list(:project_role, 3) }

  let(:row) do
    instance_double(Members::RowComponent,
                    roles_css_id: "foo",
                    toggle_item_class_name: "toggle-item-class-name")
  end

  let(:params) do
    {}
  end

  let(:form) do
    page.first("form.toggle-item-class-name", visible: false).tap do |form|
      form.native["style"] = ""
    end
  end

  context "for existing member" do
    let(:member) { build_stubbed(:member, principal:, project:) }

    it "renders form" do
      render_inline(subject)

      expect(form).not_to be_nil

      expect(form.first("input[type='submit']").value).to eq "Change"

      expect(form).to have_no_css "input[name='member[user_ids][]']", visible: :hidden # rubocop:disable Capybara/SpecificMatcher
    end
  end

  context "for new member" do
    let(:member) { build(:member, principal:, project:) }

    it "renders form" do
      render_inline(subject)

      expect(form).not_to be_nil

      expect(form.first("input[type='submit']").value).to eq "Add"

      expect(form).to have_css "input[name='member[user_ids][]']", visible: :hidden # rubocop:disable Capybara/SpecificMatcher

      expect(form.first("input[name='member[user_ids][]']", visible: :hidden).value).to eq "42"
    end
  end
end
