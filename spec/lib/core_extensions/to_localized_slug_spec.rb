require "spec_helper"

RSpec.describe CoreExtensions::String, "#to_localized_slug" do
  let(:input) { "dübelbädel! ..." }
  let(:slug) { input.to_localized_slug }

  it "uses english by default" do
    expect(slug).to eq "dubelbadel-dot-dot-dot"
  end

  context "with a limit and german locale" do
    let(:slug) { input.to_localized_slug(locale: :de, limit: 4) }

    it "limits the localized string" do
      expect(slug).to eq "dueb"
    end
  end

  context "with a limit and english locale" do
    let(:slug) { input.to_localized_slug(locale: :en, limit: 4) }

    it "limits the localized string" do
      expect(slug).to eq "dube"
    end
  end

  context "with a different I18n.locale" do
    before do
      I18n.locale = :de
    end

    it "uses that locale but does not change the backend locale" do
      expect { slug }.not_to change { Stringex::Localization.locale }
      expect(slug).to eq "duebelbaedel-punkt-punkt-punkt"
    end
  end

  context "passing in the locale" do
    let(:slug) { input.to_localized_slug(locale: :de) }

    it "uses that locale but does not change the backend locale" do
      expect { slug }.not_to change { Stringex::Localization.locale }
      expect(slug).to eq "duebelbaedel-punkt-punkt-punkt"
    end
  end
end
