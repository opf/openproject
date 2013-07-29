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

describe OpenProject::JournalFormatter::ScenarioDate do

  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper

  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  include Redmine::I18n

  struct = Struct.new("TimelinesScenarioDateTestJournal", :id, :journaled)

  let(:klass) { OpenProject::JournalFormatter::ScenarioDate }
  let(:journal_id) { 1 }
  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:journal) do
    Struct::TimelinesScenarioDateTestJournal.new(journal_id, scenario)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { "scenario_#{scenario.id}_#{date_type}_date" }
  let(:date_type) { "start" }

  describe :render do
    describe "WITH rendering the start date
              WITH the first value beeing nil, and the second a date
              WITH the scenario existing" do
      let(:new_date) { Date.today }
      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "<strong>#{ I18n.t(:"label_scenario_#{date_type}_date", :title => scenario.name) }</strong>",
                              :value => "<i>#{format_date(new_date)}</i>") }

      it { instance.render(key, [nil, new_date]).should == expected }
    end

    describe "WITH rendering the due date
              WITH the first value beeing nil, and the second a date
              WITH the scenario existing" do
      let(:new_date) { Date.today }
      let(:date_type) { "due" }
      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "<strong>#{ I18n.t(:"label_scenario_#{date_type}_date", :title => scenario.name) }</strong>",
                              :value => "<i>#{format_date(new_date)}</i>") }

      it { instance.render(key, [nil, new_date]).should == expected }
    end

    describe "WITH rendering the start date
              WITH the first value beeing a date, and the second a date
              WITH the scenario existing" do
      let(:old_date) { Date.today - 4.days }
      let(:new_date) { Date.today }
      let(:expected) { I18n.t(:text_journal_changed,
                              :label => "<strong>#{ I18n.t(:"label_scenario_#{date_type}_date", :title => scenario.name) }</strong>",
                              :new => "<i>#{format_date(new_date)}</i>",
                              :old => "<i>#{format_date(old_date)}</i>") }

      it { instance.render(key, [old_date, new_date]).should == expected }
    end

    describe "WITH rendering the start date
              WITH the first value beeing a date, and the second nil
              WITH the scenario existing" do
      let(:old_date) { Date.today - 4.days }
      let(:expected) { I18n.t(:text_journal_deleted,
                              :label => "<strong>#{ I18n.t(:"label_scenario_#{date_type}_date", :title => scenario.name) }</strong>",
                              :old => "<strike><i>#{format_date(old_date)}</i></strike>") }

      it { instance.render(key, [old_date, nil]).should == expected }
    end

    describe "WITH rendering the start date
              WITH the first value beeing nil, and the second a date
              WITH the scenario is deleted" do
      let(:new_date) { Date.today }
      let(:key) { "scenario_0_#{date_type}_date" }
      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "<strong>#{ I18n.t(:"label_scenario_#{date_type}_date",
                                                           :title => I18n.t(:label_scenario_deleted)) }</strong>",
                              :value => "<i>#{format_date(new_date)}</i>") }

      it { instance.render(key, [nil, new_date]).should == expected }
    end
  end
end
