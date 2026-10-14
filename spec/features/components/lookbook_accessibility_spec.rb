# frozen_string_literal: true

require "rails_helper"

Rails.root.glob("lookbook/previews/**/*_preview.rb").each { |f| require f.to_s }

# To mark a component preview as pending, add the name and a reason here, using the format:
# "OpPrimer::StatusButtonComponentPreview" => "Needs design change",
# To mark only a specific preview instead of all previews for that component, add the name separated with a `#`
# "OpPrimer::StatusButtonComponentPreview#playground" => "Needs design change",
AXE_KNOWN_VIOLATIONS = {
  "OpPrimer::StatusButtonComponentPreview" => "Needs design change"
}.freeze

RSpec.describe "Lookbook previews accessibility", :component_preview, :js, :selenium do
  ViewComponent::Preview.all.each do |preview|
    describe preview.name do
      preview.examples.each do |example|
        it "#{example} has no WCAG violations in its default state" do
          key = [preview.name, "#{preview.name}##{example}"]

          if (reason = AXE_KNOWN_VIOLATIONS.values_at(*key).compact.first)
            pending reason
          end

          visit_preview(example.to_sym, from: preview)

          expect(page).to be_axe_clean.within(".viewcomponent-preview--content")
        end
      end
    end
  end
end
