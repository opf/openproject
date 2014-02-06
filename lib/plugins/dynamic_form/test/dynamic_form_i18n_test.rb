require 'test_helper'

class DynamicFormI18nTest < Test::Unit::TestCase
  include ActionView::Context
  include ActionView::Helpers::DynamicForm

  attr_reader :request

  def setup
    @object = stub :errors => stub(:count => 1, :full_messages => ['full_messages'])
    @object.stub :to_model => @object
    @object.stub :class => stub(:model_name => stub(:human => ""))

    @object_name = 'book_seller'
    @object_name_without_underscore = 'book seller'

    stub(:content_tag).and_return 'content_tag'

    I18n.stub(:t).with(:'header', :locale => 'en', :scope => [:errors, :template], :count => 1, :model => '').and_return "1 error prohibited this  from being saved"
    I18n.stub(:t).with(:'body', :locale => 'en', :scope => [:errors, :template]).and_return 'There were problems with the following fields:'
  end

  def test_error_messages_for_given_a_header_option_it_does_not_translate_header_message
    I18n.should_receive(:t).with(:'header', :locale => 'en', :scope => [:errors, :template], :count => 1, :model => '').never
    error_messages_for(:object => @object, :header_message => 'header message', :locale => 'en')
  end

  def test_error_messages_for_given_no_header_option_it_translates_header_message
    I18n.should_receive(:t).with(:'header', :locale => 'en', :scope => [:errors, :template], :count => 1, :model => '').and_return 'header message'
    error_messages_for(:object => @object, :locale => 'en')
  end

  def test_error_messages_for_given_a_message_option_it_does_not_translate_message
    I18n.should_receive(:t).with(:'body', :locale => 'en', :scope => [:errors, :template]).never
    error_messages_for(:object => @object, :message => 'message', :locale => 'en')
  end

  def test_error_messages_for_given_no_message_option_it_translates_message
    I18n.should_receive(:t).with(:'body', :locale => 'en', :scope => [:errors, :template]).and_return 'There were problems with the following fields:'
    error_messages_for(:object => @object, :locale => 'en')
  end
end