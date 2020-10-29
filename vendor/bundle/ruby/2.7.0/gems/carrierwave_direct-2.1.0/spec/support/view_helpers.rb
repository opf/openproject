# encoding: utf-8

require 'capybara/rspec'

module ViewHelpers
  include Capybara::RSpecMatchers

  def parent_selector
    defined?(super) ? super : @parent_selector ||= []
  end

  def have_parent_selector(options = {})
    have_selector(:xpath, parent_selector_xpath, options.merge(visible: false))
  end

  def parent_selector_xpath
    xpath = parent_selector.join("/")
    xpath = ".//#{xpath}" unless xpath[0..2] == ".//"
    xpath
  end

  def submit_to(options = {})
    xpath_attributes = to_xpath_attributes(options)
    parent_selector << "form[#{xpath_attributes}]"
    have_parent_selector
  end

  def to_xpath_attributes(options = {})
    attributes = []

    options.each do |key, value|
      attributes << ((value == false) ? "not(@#{key})" : "@#{key}='#{value}'")
    end

    attributes.join(" and ")
  end

  def have_input(resource_name, input, options = {})
    count = (options.delete :count).to_i
    selector_options = count > 0 ? {:count => count} : {}

    options[:type] ||= input
    options[:id] ||= "#{resource_name}_#{input}"
    options[:name] ||= "#{resource_name}[#{input}]"
    options[:required] ||= "required" unless options[:required] == false
    parent_selector << "input[#{to_xpath_attributes(options)}]"
    have_parent_selector selector_options
  end

  def have_content_type(content_type,selected=nil)
    options = {:value => content_type}
    options[:selected] = 'selected' if selected

    have_selector :xpath, ".//select[@name=\"Content-Type\"]/option[#{to_xpath_attributes(options)}]"
  end
end

