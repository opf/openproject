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

RSpec.describe OpenProject::Common::InplaceEditFieldDialogComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project) }
  let(:allowed_attributes) { %w[description] }
  let(:contract) do
    contract = instance_double(BaseContract)
    allow(contract).to receive(:writable?) { |attr| allowed_attributes.include?(attr.to_s) }
    allow(contract).to receive(:model).and_return(instance_double(Project))
    contract
  end
  let(:contract_class) do
    instance_double(Class).tap do |klass|
      allow(klass).to receive(:new).with(project, User.current).and_return(contract)
    end
  end
  let(:update_registry) do
    registry = OpenProject::InplaceEdit::UpdateRegistry.new
    registry.register(Project, handler: double, contract: contract_class)
    registry
  end

  before { allow(User).to receive(:current).and_return(build_stubbed(:user)) }

  it "renders a dialog with the expected ID and label" do
    render_inline(described_class.new(model: project, attribute: :description,
                                      system_arguments: { update_registry:, writable: true }))

    expect(rendered_content).to have_css("#inplace-edit-field-dialog--project-#{project.id}--description")
    expect(rendered_content).to have_text(Project.human_attribute_name(:description))
  end

  it "uses system_arguments[:label] as dialog title when provided" do
    render_inline(
      described_class.new(
        model: project,
        attribute: :description,
        system_arguments: { update_registry:, writable: true, label: "My Label" }
      )
    )

    expect(rendered_content).to have_text("My Label")
  end

  context "when the user has write access" do
    let(:allowed_attributes) { %w[description] }

    it "renders the edit form in the dialog body" do
      render_inline(described_class.new(model: project, attribute: :description,
                                        system_arguments: { update_registry:, writable: true }))

      expect(rendered_content).to have_test_selector("op-inplace-edit-field--form")
    end

    it "renders Cancel and Save buttons in the footer" do
      render_inline(described_class.new(model: project, attribute: :description,
                                        system_arguments: { update_registry:, writable: true }))

      expect(rendered_content).to have_button(I18n.t(:button_cancel))
      expect(rendered_content).to have_button(I18n.t(:button_save))
    end
  end

  context "when the user does not have write access" do
    let(:allowed_attributes) { [] }

    it "renders the display component in the dialog body instead of the edit form" do
      render_inline(described_class.new(model: project, attribute: :description,
                                        system_arguments: { update_registry:, writable: false }))

      expect(rendered_content).not_to have_test_selector("op-inplace-edit-field--form")
      expect(rendered_content).to have_css(".op-inplace-edit--display-field")
    end

    it "renders only a Close button in the footer" do
      render_inline(described_class.new(model: project, attribute: :description,
                                        system_arguments: { update_registry:, writable: false }))

      expect(rendered_content).to have_button(I18n.t(:button_close))
      expect(rendered_content).to have_no_button(I18n.t(:button_cancel))
      expect(rendered_content).to have_no_button(I18n.t(:button_save))
    end
  end
end
