module Redmine
  module WikiFormatting
    module Xml
      module Helper
        def wikitoolbar_for(field_id)
          heads_for_wiki_formatter
          javascript_tag("tinyMCE.execCommand(\"mceAddControl\", true, \"#{field_id}\");")
        end

        def initial_page_content(page)
          ("<h1>".html_safe + page.pretty_title.to_s + "<h1>".html_safe).html_safe
        end

        def heads_for_wiki_formatter
          unless @heads_for_wiki_formatter_included
            content_for :header_tags do
              javascript_include_tag('tiny_mce/tiny_mce') +
              javascript_include_tag('tiny_mce_configuration')
            end
            @heads_for_wiki_formatter_included = true
          end
        end
      end
    end
  end
end

# register test macro
Redmine::WikiFormatting::Macros.register do
  desc <<-EOF
    Display a kitten.
  EOF

  macro :kitten do |obj, args, options|
    if options[:edit]
      image_tag "http://www.adoptny.org/wp-content/themes/adoptny/img/placeholder.png", :alt => 'A kitten'
    else
      width = args.first || 400
      height = args.second || 401
      image_tag "http://placekitten.com/#{width}/#{height}", :alt => 'A kitten'
    end
  end
end