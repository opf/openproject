# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe EnterpriseEdition::BannerComponent, type: :component do
  let(:title) { "Some title" }
  let(:expected_title) { title }
  let(:description) { "Some description" }
  let(:expected_description) { description }
  let(:href) { "https://www.example.org" }
  let(:component_test_selector) { "op-enterprise-banner" }
  let(:features) { nil }
  let(:plan) { :basic }
  let(:enforce_available_locales) { I18n.config.enforce_available_locales }
  let(:i18n_upsell) do
    {
      some_enterprise_feature: {
        title:,
        description:,
        features:
      }.compact
    }
  end

  let(:enterprise_feature_link) { href }

  let(:translations) do
    {
      ee: {
        features: {
          some_enterprise_feature: "Enterprise feature translation"
        },
        upsell: i18n_upsell
      }
    }
  end
  let(:component_args) { {} }

  let(:render_component) do
    render_inline(described_class.new(:some_enterprise_feature, **component_args))
  end

  let(:render_component_in_mo) do
    I18n.with_locale :mo do
      render_component
    end
  end

  before do
    allow(OpenProject::Static::Links)
      .to receive(:url_for)
      .and_call_original

    allow(OpenProject::Static::Links)
      .to receive(:url_for)
      .with(:enterprise_features, :some_enterprise_feature, any_args)
      .and_return(enterprise_feature_link)

    allow(OpenProject::Token)
      .to receive(:lowest_plan_for)
            .with(:some_enterprise_feature)
            .and_return(plan)

    I18n.config.enforce_available_locales = !enforce_available_locales

    I18n.backend.store_translations(
      :mo,
      translations
    )
  end

  after do
    I18n.backend.translations.delete(:mo)
    I18n.config.enforce_available_locales = enforce_available_locales
  end

  shared_examples_for "renders the component" do
    it "renders the component" do
      render_component_in_mo

      component = find_test_selector(component_test_selector)

      expect(component).to have_text(expected_title)
      expect(component).to have_text(expected_description)
      expect(component).to have_link("More information", href:)
    end
  end

  shared_examples_for "does not render the component" do
    it "does not render the component" do
      render_component_in_mo

      expect(page).not_to have_test_selector(component_test_selector)
      expect(page).to have_no_text("Enterprise feature translation")
      expect(page).to have_no_text(expected_title)
      expect(page).to have_no_text(expected_description)
      expect(page).to have_no_link(href:)
    end
  end

  it_behaves_like "renders the component"

  context "when feature is available", with_ee: %i[some_enterprise_feature] do
    it_behaves_like "does not render the component"
  end

  context "when banners are hidden" do
    before do
      allow(EnterpriseToken).to receive(:hide_banners?).and_return(true)
    end

    it_behaves_like "does not render the component"
  end

  context "when banner is dismissed" do
    let(:preference) { build_stubbed(:user_preference) }
    let(:user) { build_stubbed(:user, preference:) }
    let(:dismiss_key) { "some_enterprise_feature" }
    let(:component_args) { { dismissable: true } }

    before do
      login_as(user)
      allow(preference)
        .to receive(:dismissed_banner?)
              .with(dismiss_key)
              .and_return(true)
    end

    it_behaves_like "does not render the component"

    context "when not dismissable" do
      let(:component_args) { { dismissable: false } }

      it_behaves_like "renders the component"
    end

    context "when using a custom dismiss_key" do
      let(:dismiss_key) { "foo" }
      let(:component_args) { { dismiss_key:, dismissable: true } }

      it_behaves_like "does not render the component"
    end
  end

  context "without a title, but a description_html" do
    let(:i18n_upsell) do
      {
        some_enterprise_feature: {
          description_html: description
        }
      }
    end
    let(:expected_title) { "Enterprise feature translation" }

    it_behaves_like "renders the component"
  end

  context "without a title, but a description" do
    let(:i18n_upsell) do
      {
        some_enterprise_feature: {
          description:
        }
      }
    end
    let(:expected_title) { "Enterprise feature translation" }

    it_behaves_like "renders the component"
  end

  context "with a more specific title in the i18n file" do
    let(:i18n_upsell) do
      {
        some_enterprise_feature: {
          title:,
          description:
        }
      }
    end

    it_behaves_like "renders the component"
  end

  context "with a custom i18n_scope" do
    let(:translations) do
      {
        my: {
          custom: {
            upsell: {
              title: "Foo",
              description: "Bar"
            }
          }
        },
        ee: {
          features: {
            some_enterprise_feature: "Enterprise feature translation"
          }
        }
      }
    end
    let(:expected_title) { "Foo" }
    let(:expected_description) { "Bar" }
    let(:component_args) { { i18n_scope: "my.custom.upsell" } }

    it_behaves_like "renders the component"
  end

  context "without a description key in the i18n file" do
    let(:i18n_upsell) do
      {
        some_enterprise_feature: {}
      }
    end

    it "raises an error" do
      expect { render_component_in_mo }.to raise_error(I18n::MissingTranslationData)
    end
  end

  context "without a link key in the static_link file" do
    let(:enterprise_feature_link) { nil }

    it "uses the default" do
      render_component_in_mo

      component = find_test_selector(component_test_selector)

      expect(component).to have_text(expected_title)
      expect(component).to have_text(expected_description)

      expect(component).to have_link("More information", href: "https://www.openproject.org/enterprise-edition?go_to_locale=mo")
    end
  end

  context "with large variant" do
    context "with video parameter" do
      let(:component_args) { { variant: :large, video: "enterprise/date-alert-notifications.mp4" } }

      it_behaves_like "renders the component"

      it "renders with large variant class" do
        render_component_in_mo

        component = find_test_selector(component_test_selector)

        expect(component[:class]).to include("op-enterprise-banner_large")

        expect(component).to have_css('video[src$="/enterprise/date-alert-notifications.mp4"]')
      end
    end

    context "with image parameter" do
      let(:component_args) { { variant: :large, image: "enterprise/homescreen.png" } }

      it_behaves_like "renders the component"

      it "renders with large variant class" do
        render_component_in_mo

        component = find_test_selector(component_test_selector)

        expect(component[:class]).to include("op-enterprise-banner_large")

        expect(component).to have_css('img[src$="/enterprise/homescreen.png"]')
      end
    end

    context "with video and image parameters" do
      let(:component_args) do
        { variant: :large, video: "enterprise/date-alert-notifications.mp4", image: "enterprise/homescreen.png" }
      end

      it "raises an error" do
        expect { render_component_in_mo }
          .to raise_error(ArgumentError, "Only one of 'image' and 'video' parameters can be specified for variant :large")
      end
    end

    context "without video and image parameters" do
      let(:component_args) { { variant: :large } }

      it "raises an error" do
        expect { render_component_in_mo }
          .to raise_error(ArgumentError, "Either 'image' or 'video' parameter is required for variant :large")
      end
    end
  end

  context "with a trial token", :with_ee_trial, with_ee: [:some_enterprise_feature] do
    current_user { build(:admin) }

    it_behaves_like "renders the component"

    it "renders with trial overrides" do
      render_component_in_mo

      component = find_test_selector(component_test_selector)

      expect(component[:class]).to include("op-enterprise-banner_trial")
      expect(component[:class]).not_to include("op-enterprise-banner_medium")
      expect(component[:class]).not_to include("op-enterprise-banner_large")

      expect(component).to have_css(".op-enterprise-banner--dismiss")
      expect(component).to have_content("Buy now")
      expect(component).to have_content("This feature is included in your active Enterprise trial.")
    end
  end
end
