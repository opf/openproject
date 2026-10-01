# frozen_string_literal: true

RSpec.shared_examples "renders identifier_suggestion_data" do
  it "mounts the Stimulus controller on the wrapper" do
    expect(rendered_component).to have_css("[data-controller='projects--identifier-suggestion']")
  end

  it "includes the suggestion URL" do
    expect(rendered_component).to have_css(
      "[data-projects--identifier-suggestion-url-value='/projects/identifier_suggestion']"
    )
  end

  it "includes the set_name_first translation" do
    translation = I18n.t("js.projects.identifier_suggestion.set_name_first")
    expect(rendered_component).to have_css(
      "[data-projects--identifier-suggestion-set-name-first-value='#{translation}']"
    )
  end

  context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "sets mode to semantic" do
      expect(rendered_component).to have_css("[data-projects--identifier-suggestion-mode-value='semantic']")
    end
  end

  context "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
    it "sets mode to classic" do
      expect(rendered_component).to have_css("[data-projects--identifier-suggestion-mode-value='classic']")
    end
  end
end
