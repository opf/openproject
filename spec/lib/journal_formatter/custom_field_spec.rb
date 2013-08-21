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

describe OpenProject::JournalFormatter::CustomField do

  include CustomFieldsHelper
  include ActionView::Helpers::TagHelper

  Struct.new("TestJournal", :id)

  let(:klass) { OpenProject::JournalFormatter::CustomField }
  let(:instance) { klass.new(journal) }
  let(:id) { 1 }
  let(:journal) do
    Struct::TestJournal.new(id)
  end
  let(:user) { FactoryGirl.create(:user) }
  let(:custom_field) { FactoryGirl.create(:issue_custom_field) }
  let(:key) { "custom_fields_#{custom_field.id}" }

  describe :render do
    describe "WITH the first value beeing nil, and the second a valid value as string" do
      let(:values) { [nil, "1"] }

      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "<strong>#{custom_field.name}</strong>",
                              :value => "<i>#{ format_value(values.last, custom_field.field_format) }</i>") }

      it { instance.render(key, values).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing a valid value as a string" do
      let(:values) { ["0", "1"] }

      let(:expected) { I18n.t(:text_journal_changed,
                              :label => "<strong>#{custom_field.name}</strong>",
                              :old => "<i>#{ format_value(values.first, custom_field.field_format) }</i>",
                              :new => "<i>#{ format_value(values.last, custom_field.field_format) }</i>") }

      it { instance.render(key, values).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing nil" do
      let(:values) { ["0", nil] }

      let(:expected) { I18n.t(:text_journal_deleted,
                              :label => "<strong>#{custom_field.name}</strong>",
                              :old => "<strike><i>#{ format_value(values.first, custom_field.field_format) }</i></strike>") }

      it { instance.render(key, values).should == expected }
    end

    describe "WITH the first value beeing nil, and the second a valid value as string
              WITH no html requested" do
      let(:values) { [nil, "1"] }

      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "#{custom_field.name}",
                              :value => "#{ format_value(values.last, custom_field.field_format) }") }

      it { instance.render(key, values, :no_html => true).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing a valid value as a string
              WITH no html requested" do
      let(:values) { ["0", "1"] }

      let(:expected) { I18n.t(:text_journal_changed,
                              :label => "#{custom_field.name}",
                              :old => "#{ format_value(values.first, custom_field.field_format) }",
                              :new => "#{ format_value(values.last, custom_field.field_format) }") }

      it { instance.render(key, values, :no_html => true).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing nil
              WITH no html requested" do
      let(:values) { ["0", nil] }

      let(:expected) { I18n.t(:text_journal_deleted,
                              :label => "#{custom_field.name}",
                              :old => "#{ format_value(values.first, custom_field.field_format) }") }

      it { instance.render(key, values, :no_html => true).should == expected }
    end

    describe "WITH the first value beeing nil, and the second a valid value as string
              WITH the custom field beeing deleted" do
      let(:values) { [nil, "1"] }
      let(:key) { "custom_values0" }

      let(:expected) { I18n.t(:text_journal_set_to,
                              :label => "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
                              :value => "<i>#{ values.last }</i>") }

      it { instance.render(key, values).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing a valid value as a string
              WITH the custom field beeing deleted" do
      let(:values) { ["0", "1"] }
      let(:key) { "custom_values0" }

      let(:expected) { I18n.t(:text_journal_changed,
                              :label => "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
                              :old => "<i>#{ values.first }</i>",
                              :new => "<i>#{ values.last }</i>") }

      it { instance.render(key, values).should == expected }
    end

    describe "WITH the first value beeing a valid value as a string, and the second beeing nil
              WITH the custom field beeing deleted" do
      let(:values) { ["0", nil] }
      let(:key) { "custom_values0" }

      let(:expected) { I18n.t(:text_journal_deleted,
                              :label => "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
                              :old => "<strike><i>#{ values.first }</i></strike>") }

      it { instance.render(key, values).should == expected }
    end
  end
end
