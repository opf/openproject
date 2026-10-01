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

RSpec.describe CustomFields::CommentField, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:project_custom_field, :has_comment, name: "Project custom field") }

  it_behaves_like "rendering label", "Comment"

  context "when showing complete label" do
    def build_form(builder)
      described_class.new(builder, custom_field:, object: model, complete_label: true)
    end

    it_behaves_like "rendering label", "Project custom field comment"
  end

  context "without a value" do
    it "renders field" do
      expect(rendered_form).to have_field "Comment", type: :textarea, with: ""
    end
  end

  context "with a value" do
    before do
      model.update!(custom_field.comment_attribute_name => "hello, world!")
    end

    it "renders field" do
      expect(rendered_form).to have_field "Comment", type: :textarea, with: "hello, world!"
    end
  end
end
