module Redmine
  module WikiFormatting
    module Xml
      module Helper
        def wikitoolbar_for(field_id)
          tinymce_initialization = @tiny_mce_initialized ? "".html_safe : tinymce
          @tiny_mce_initialized = true
          tinymce_initialization + javascript_tag("tinyMCE.execCommand(\"mceAddControl\", true, \"#{field_id}\");")
        end

        def initial_page_content(page)
          ("<h1>".html_safe + page.pretty_title.to_s + "<h1>".html_safe).html_safe
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

  macro :rndimg do |obj, args, options|
    if options[:edit]
      image_tag "http://www.adoptny.org/wp-content/themes/adoptny/img/placeholder.png", :alt => 'A kitten'
    else
      width = args.first || 400
      height = args.second || 401
      url = "http://tessenow.org/rndimg/#{width}/#{height}"
      url << "/#{args[2]}" if args[2]
      image_tag url, :alt => 'A random image'
    end
  end
end