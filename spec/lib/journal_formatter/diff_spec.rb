#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

describe OpenProject::JournalFormatter::Diff do

  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper
    Rails.application.routes.url_helpers
  end

  Struct.new("TestJournal", :id, :journable)

  let(:klass) { OpenProject::JournalFormatter::Diff }
  let(:id) { 1 }
  let(:journal) do
    Struct::TestJournal.new(id, Issue.new)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { "description" }

  let(:url) {  url_helper.journal_diff_path(:id => journal.id,
                                            :field => key.downcase)}
  let(:full_url) { url_helper.journal_diff_url(:id => journal.id,
                                               :field => key.downcase,
                                               :protocol => Setting.protocol,
                                               :host => Setting.host_name) }
  let(:link) { link_to(I18n.t(:label_details), url, :class => 'description-details') }
  let(:full_url_link) { link_to(I18n.t(:label_details), full_url, :class => 'description-details') }

  describe :render do
    describe "WITH the first value beeing nil, and the second a string" do
      let(:expected) { I18n.t(:text_journal_set_with_diff,
                              :label => "<strong>#{key.camelize}</strong>",
                              :link => link) }

      it { instance.render(key, [nil, "new value"]).should == expected }
    end

    describe "WITH the first value beeing a string, and the second a string" do
      let(:expected) { I18n.t(:text_journal_changed_with_diff,
                              :label => "<strong>#{key.camelize}</strong>",
                              :link => link) }

      it { instance.render(key, ["old value", "new value"]).should == expected }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH de as locale" do

      let(:expected) { I18n.t(:text_journal_changed_with_diff,
                              :label => "<strong>Beschreibung</strong>",
                              :link => link) }

      before do
        I18n.locale = :de
      end

      it { instance.render(key, ["old value", "new value"]).should == expected }

      after do
        I18n.locale = :en
      end
    end

    describe "WITH the first value beeing a string, and the second nil" do
      let(:expected) { I18n.t(:text_journal_deleted_with_diff,
                              :label => "<strong>#{key.camelize}</strong>",
                              :link => link) }

      it { instance.render(key, ["old_value", nil]).should == expected }
    end

    describe "WITH the first value beeing nil, and the second a string
              WITH specifying not to output html" do
      let(:expected) { I18n.t(:text_journal_set_with_diff,
                              :label => key.camelize,
                              :link => url) }

      it { instance.render(key, [nil, "new value"], :no_html => true).should == expected }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH specifying not to output html" do
      let(:expected) { I18n.t(:text_journal_changed_with_diff,
                              :label => key.camelize,
                              :link => url) }

      it { instance.render(key, ["old value", "new value"], :no_html => true).should == expected }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH specifying to output a full url" do
      let(:expected) { I18n.t(:text_journal_changed_with_diff,
                              :label => "<strong>#{key.camelize}</strong>",
                              :link => full_url_link) }

      it { instance.render(key, ["old value", "new value"], :only_path => false).should == expected }
    end

    describe "WITH the first value beeing a string, and the second nil" do
      let(:expected) { I18n.t(:text_journal_deleted_with_diff,
                              :label => key.camelize,
                              :link => url) }

      it { instance.render(key, ["old_value", nil], :no_html => true).should == expected }
    end
  end
end
