require 'redmine'

Redmine::Plugin.register :wysiwyg_editing do
  name 'ChiliProject WYSIWYG editing Plugin'
  author 'Philipp Tessenow'
  description 'This plugin provides the ability to edit text either with plain old textile or a wysiwyg-editor.'

  version '0.0.1'
  url 'http://github.com/finnlabs/wysiwyg_editing'
  author_url 'http://www.finn.de/'
end

require 'dispatcher'
Dispatcher.to_prepare :wysiwyg_editing do
  require_dependency 'wysiwyg_editing/patches/wiki_formatter_xml'
  require_dependency 'wysiwyg_editing/patches/wiki_formatter_xml_helper'

  #require 'ruby-debug'; debugger

  Redmine::WikiFormatting.map do |format|
    format.register :xml, Redmine::WikiFormatting::Xml::Formatter, Redmine::WikiFormatting::Xml::Helper
  end
end
