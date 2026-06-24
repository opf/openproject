# frozen_string_literal: true

require "spec_helper"

RSpec.describe My::AttributesForm, type: :forms do
  # NOTE: My::AttributesForm builds its own contract during render, and the
  # shared "with rendered form" context renders in a `before` of its own. This
  # setup `before` is declared ahead of the include so the contract stub is in
  # place before that render runs; the `let`s follow the include so they win
  # over the shared context's defaults (e.g. `params`).
  before do
    User.current = current_user
    allow(Users::UpdateContract).to receive(:new).and_return(contract)
    allow(contract).to receive(:writable?) { |attr| writable_attributes.include?(attr.to_sym) }
  end

  include_context "with rendered form"

  let(:writable_attributes) { %i[firstname lastname mail language] } # internal user; login never writable
  let(:contract) { instance_double(Users::UpdateContract) }
  let(:current_user) { model }
  let(:model) { build_stubbed(:user) }
  let(:params) { { user: model } }

  context "for an internal user" do
    it "renders editable name/mail, a language select, and a read-only login" do
      expect(page).to have_field("user[firstname]")
      expect(page).to have_no_field("user[firstname]", readonly: true)
      expect(page).to have_field("user[lastname]")
      expect(page).to have_field("user[mail]")
      expect(page).to have_select("user[language]")
      expect(page).to have_field("user[login]", readonly: true)
    end

    it "omits the admin flag and the account section" do
      expect(page).to have_no_field("user[admin]")
      expect(page).to have_no_css("fieldset", text: I18n.t(:label_account))
    end
  end

  context "for a provider-managed login (name and email not writable)" do
    let(:writable_attributes) { %i[language] }

    it "renders name and mail read-only with the provider caption" do
      expect(page).to have_field("user[firstname]", readonly: true)
      expect(page).to have_field("user[lastname]", readonly: true)
      expect(page).to have_field("user[mail]", readonly: true)
      expect(page).to have_text(I18n.t("user.text_change_disabled_for_provider_login"), count: 3)
    end
  end
end
