module Redmine
  module WikiFormatting
    module Xml
      module Helper
        def wikitoolbar_for(field_id)
          heads_for_wiki_formatter
          javascript_tag("tinyMCE.execCommand(\"mceAddControl\", true, \"#{field_id}\");")
        end

        def initial_page_content(page)
          page.pretty_title.to_s
        end

        def heads_for_wiki_formatter
          unless @heads_for_wiki_formatter_included
            content_for :header_tags do
              javascript_include_tag('lib/tiny_mce/tiny_mce',      :plugin => 'wysiwyg_editing') +
              javascript_include_tag('app/tiny_mce_configuration', :plugin => 'wysiwyg_editing')
            end
            @heads_for_wiki_formatter_included = true
          end
        end
      end
    end
  end
end