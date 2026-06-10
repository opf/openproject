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

RSpec.describe ApplicationHelper do
  describe ".link_to_if_authorized" do
    let(:project) { create(:valid_project) }
    let(:project_member) do
      create(:user,
             member_with_permissions: { project => %i[view_work_packages edit_work_packages
                                                      browse_repository view_changesets view_wiki_pages] })
    end
    let(:issue) do
      create(:work_package,
             project:,
             author: project_member,
             type: project.types.first)
    end

    context "if user is authorized" do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized("link_content", {
                                            controller: "work_packages",
                                            action: "show",
                                            id: issue
                                          },
                                          class: "fancy_css_class")
      end

      subject { @response }

      it { is_expected.to match /href/ }

      it { is_expected.to match /fancy_css_class/ }
    end

    context "if user is unauthorized" do
      before do
        expect(self).to receive(:authorize_for).and_return(false)
        @response = link_to_if_authorized("link_content", {
                                            controller: "work_packages",
                                            action: "show",
                                            id: issue
                                          },
                                          class: "fancy_css_class")
      end

      subject { @response }

      it { is_expected.to be_nil }
    end

    context "allow using the :controller and :action for the target link" do
      before do
        expect(self).to receive(:authorize_for).and_return(true)
        @response = link_to_if_authorized("By controller/action",
                                          controller: "work_packages",
                                          action: "show",
                                          id: issue.id)
      end

      subject { @response }

      it { is_expected.to match /href/ }
    end
  end

  describe "other_formats_links" do
    context "link given" do
      before do
        @links = other_formats_links { |f| f.link_to "Atom", url: { controller: :projects, action: :index } }
      end

      it {
        expect(@links).to be_html_eql("<p class=\"other-formats\">Also available in:<span><a class=\"icon icon-atom\" href=\"/projects.atom\" rel=\"nofollow\">Atom</a></span></p>")
      }
    end

    context "link given but disabled" do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(false)
        @links = other_formats_links { |f| f.link_to "Atom", url: { controller: :projects, action: :index } }
      end

      it { expect(@links).to be_nil }
    end
  end

  describe "time_tag" do
    around do |example|
      I18n.with_locale(:en) { example.run }
    end

    subject { time_tag(time) }

    context "with project" do
      before do
        @project = build(:project)
      end

      context "right now" do
        let(:time) { Time.now }

        it { is_expected.to match /^<a/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context "some time ago" do
        let(:time) do
          Timecop.travel(2.weeks.ago) do
            Time.now
          end
        end

        it { is_expected.to match /^<a/ }
        it { is_expected.to match /14 days/ }
        it { is_expected.to be_html_safe }
      end
    end

    context "without project" do
      context "right now" do
        let(:time) { Time.now }

        it { is_expected.to match /^<time/ }
        it { is_expected.to match /datetime="#{Regexp.escape(time.xmlschema)}"/ }
        it { is_expected.to match /less than a minute/ }
        it { is_expected.to be_html_safe }
      end

      context "some time ago" do
        let(:time) do
          Timecop.travel(1.week.ago) do
            Time.now
          end
        end

        it { is_expected.to match /^<time/ }
        it { is_expected.to match /datetime="#{Regexp.escape(time.xmlschema)}"/ }
        it { is_expected.to match /7 days/ }
        it { is_expected.to be_html_safe }
      end
    end
  end

  describe ".authoring_at" do
    it "escapes html from author name" do
      created = "2023-06-02"
      author = build(:user, firstname: "<b>Hello</b>", lastname: "world")
      author.save! validate: false

      esc_name = "&lt;b&gt;Hello&lt;/b&gt; world"

      exp_str = <<-HTML.squish
        Added by
        <a title="User #{esc_name}" data-hover-card-url="/users/#{author.id}/hover_card"
           data-hover-card-trigger-target="trigger" href="/users/#{author.id}">#{esc_name}</a>
        on 2023-06-02
      HTML

      expect(authoring_at(created, author))
        .to eq(exp_str)
    end
  end

  describe "#lang_options_for_select" do
    before do
      allow(Redmine::I18n)
        .to receive(:all_languages)
        .and_return %w[en de es ja zh-CN]
    end

    context "with all available languages" do
      it "returns options for all languages" do
        expect(lang_options_for_select).to eq [
          ["(auto)", ""],
          ["Deutsch", "de", { lang: "de" }],
          ["English", "en", { lang: "en" }],
          ["Español", "es", { lang: "es" }],
          ["日本語", "ja", { lang: "ja" }],
          ["简体中文", "zh-CN", { lang: "zh-CN" }]
        ]
      end
    end

    context "with some available languages", with_settings: { available_languages: %w[en es ja] } do
      it "returns options for available languages" do
        expect(lang_options_for_select).to eq [
          ["English", "en", { lang: "en" }],
          ["Español", "es", { lang: "es" }],
          ["日本語", "ja", { lang: "ja" }]
        ]
      end
    end

    context "when blank is true (default)" do
      it "returns auto option if all languages available" do
        expect(lang_options_for_select).to start_with ["(auto)", ""]
      end

      it "does not return auto option if some languages available", with_settings: { available_languages: %w[en] } do
        expect(lang_options_for_select).not_to start_with ["(auto)", ""]
      end
    end

    context "when blank is false" do
      it "does not return auto option" do
        expect(lang_options_for_select(false)).not_to start_with ["(auto)", ""]
      end
    end
  end

  describe "#all_lang_options_for_select" do
    it 'has all languages translated ("English" should appear only once)' do
      impostor_locales =
        all_lang_options_for_select
          .reject { |_lang, locale| locale == "en" }
          .select { |lang, _locale| lang == "English" }
          .map { |_lang, locale| locale }
      expect(impostor_locales.count).to eq(0), <<~ERR
        The locales #{impostor_locales.to_sentence} display themselves as "English"!

        Probably because new languages were added, and the translation for their language is not
        available, so it fallbacks to the English translation.

        To fix it, generate translation files from CLDR by running

            script/i18n/generate_languages_translations

        And commit the yml files added in "config/locales/generated/*.yml".
      ERR
    end

    it "has distinct languages translation" do
      duplicate_langs =
        all_lang_options_for_select
          .map { |lang, _locale| lang }
          .tally
          .reject { |_lang, count| count == 1 }
          .map { |lang, _count| lang }
      duplicate_options =
        all_lang_options_for_select
          .filter { |lang, _locale| duplicate_langs.include?(lang) }
          .sort

      expect(duplicate_options.count).to eq(0), <<~ERR
        Some identical language names are used for different locales!

          duplicates: #{duplicate_options}

        This happens when a new language is added to Crowdin: new translation files are
        generated and the new language is available in Setting.all_languages, but there
        is no translation for its name yet, and so it falls back to "English".

        To fix it:
          - run the script "script/i18n/generate_languages_translations"
          - commit the additional translation file generated in
            "config/locales/generated/*.yml".
      ERR
    end
  end

  describe "#back_url_to_current_page" do
    context "when back_url param is provided" do
      it "returns the provided back_url" do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(back_url: "/work_packages"))

        expect(helper.back_url_to_current_page).to eq("/work_packages")
      end
    end

    context "when back_url param is missing" do
      it "returns nil" do
        allow(helper)
          .to(
            receive_messages(
              params: ActionController::Parameters.new,
              request: instance_double(ActionDispatch::Request, get?: true, url: "http://test.host/")
            )
          )

        expect(helper.back_url_to_current_page).to be_nil
      end
    end
  end

  describe "#link_to_content_update" do
    let(:options) { { controller: "work_packages", action: "show", id: 10 } }

    subject { link_to_content_update("Пакет работ", options, html_options) }

    context "without html_options" do
      let(:html_options) { {} }

      it "renders with 'target=\"_top\"'" do
        expect(subject).to be_html_eql %{
          <a target="_top" href="/work_packages/10">Пакет работ</a>
        }
      end
    end

    context "with html_options" do
      let(:html_options) { { aria: { label: "Работайте усердно!", current: "page" } } }

      it "renders with 'target=\"_top\"'" do
        expect(subject).to be_html_eql %{
          <a target="_top" aria-label="Работайте усердно!" aria-current="page" href="/work_packages/10">Пакет работ</a>
        }
      end
    end
  end
end
