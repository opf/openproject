# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackages::InfoLineComponent, type: :component do
  let(:project) { create(:project) }
  let(:status) { create(:status) }
  let(:type) { create(:type) }
  let(:work_package) { create(:work_package, project:, type:, status:) }

  subject { render_inline(described_class.new(work_package:)) }

  it "renders the work package type" do
    subject

    expect(page).to have_css("span", text: /#{Regexp.escape(type.name)}/i)
  end

  it "renders the work package status" do
    subject

    expect(page).to have_text(status.name)
  end

  it "renders a link to the work package" do
    subject

    expect(page).to have_link(href: /work_packages\/#{work_package.id}/)
  end

  describe "formatted identifier display" do
    context "when semantic mode is active",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "MYPROJ") }

      before do
        work_package.update_columns(identifier: "MYPROJ-1")
      end

      it "displays the semantic identifier without hash prefix" do
        subject

        expect(page).to have_link(text: "MYPROJ-1")
      end
    end

    context "when semantic mode is active but identifier is nil",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, identifier: "MYPROJ") }

      before do
        work_package.update_columns(identifier: nil)
      end

      it "falls back to hash-prefixed numeric id" do
        subject

        expect(page).to have_link(text: "##{work_package.id}")
      end
    end

    context "when classic mode is active",
            with_settings: { work_packages_identifier: "classic" } do
      it "displays hash-prefixed numeric id" do
        subject

        expect(page).to have_link(text: "##{work_package.id}")
      end
    end
  end
end
