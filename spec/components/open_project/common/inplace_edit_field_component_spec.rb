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

RSpec.describe OpenProject::Common::InplaceEditFieldComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project, description: "## Hello") }
  let(:user) { build_stubbed(:user) }
  let(:contract) do
    contract = instance_double(BaseContract)

    allow(contract).to receive(:writable?) do |attribute|
      allowed_attributes.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:model)
            .and_return(instance_double(Project))

    contract
  end

  let(:contract_class) do
    instance_double(Class).tap do |klass|
      allow(klass).to receive(:new)
                        .with(project, user)
                        .and_return(contract)
    end
  end

  let(:update_registry) do
    registry = OpenProject::InplaceEdit::UpdateRegistry.new
    registry.register(Project, handler: double, contract: contract_class)
    registry
  end

  before do
    allow(User).to receive(:current).and_return(user)
  end

  context "when attribute is writable" do
    let(:allowed_attributes) { %w(description) }

    it "renders display field by default" do
      render_inline(described_class.new(model: project, attribute: :description, update_registry:))

      expect(rendered_content)
        .to have_css(".op-inplace-edit--display-field.op-inplace-edit--display-field_clickable")
    end

    it "renders edit field when enforce_edit_mode is true" do
      render_inline(
        described_class.new(
          model: project,
          attribute: :description,
          enforce_edit_mode: true,
          update_registry:
        )
      )

      expect(rendered_content)
        .to have_css("form")
    end
  end

  context "when attribute is not writable" do
    let(:allowed_attributes) { %w() }

    it "does not mark display field as editable" do
      render_inline(described_class.new(model: project, attribute: :description, update_registry:))

      expect(rendered_content)
        .not_to include("click-&gt;inplace-edit#request")
      expect(rendered_content)
        .to have_no_css(".op-inplace-edit--display-field.op-inplace-edit--display-field_clickable")
    end
  end

  describe "wrapper" do
    let(:allowed_attributes) { %w(description) }

    it "renders a stable key on the wrapper for calculated field refresh" do
      render_inline(described_class.new(model: project, attribute: :description, update_registry:))

      expected_key = "project_#{project.id}_description"
      expect(rendered_content)
        .to have_css("[data-inplace-edit-stable-key='#{expected_key}']")
    end
  end

  describe "open_in_dialog" do
    let(:allowed_attributes) { %w(description) }

    it "uses the dialog controller on the display field when open_in_dialog is true" do
      render_inline(
        described_class.new(
          model: project,
          attribute: :description,
          open_in_dialog: true,
          update_registry:
        )
      )

      expect(rendered_content).to include("click-&gt;inplace-edit#openDialog")
    end
  end
end
