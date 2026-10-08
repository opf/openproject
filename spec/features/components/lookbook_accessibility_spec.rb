require "rails_helper"

Rails.root.glob("lookbook/previews/**/*_preview.rb").each { |f| require f.to_s }

RSpec.describe "Lookbook previews accessibility", :component_preview, :js, :selenium do
  ViewComponent::Preview.all.each do |preview|
    describe preview.name do
      preview.examples.each do |example|
        it "#{example} is axe clean" do
          visit_preview(example.to_sym, from: preview)

          expect(page).to be_axe_clean.within(".viewcomponent-preview--content")
        end
      end
    end
  end
end