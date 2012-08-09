module Redmine
  module WikiFormatting
    module Textile
      module Helper
        def wikitoolbar_for(field_id)
          heads_for_wiki_formatter
          if !User.current.wysiwyg_editing_preference(:enabled)
            url = url_for(:controller => 'help', :action => 'wiki_syntax')
            help_link = link_to(l(:setting_text_formatting), url,
                                :onclick => "window.open(\"#{ url }\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")

            javascript_tag("var wikiToolbar = new jsToolBar($('#{field_id}')); wikiToolbar.setHelpLink('#{escape_javascript help_link}'); wikiToolbar.draw();")
          else
            javascript_tag("tinyMCE.execCommand(\"mceAddControl\", true, \"#{field_id}\");
                            $($('#{field_id}').form).onsubmit = function() {
                                jQuery('##{field_id}').val(undress(jQuery(tinyMCE.getInstanceById('#{field_id}').getBody()).clone()[0].childNodes));
                            };")
          end
        end

        def heads_for_wiki_formatter
          unless @heads_for_wiki_formatter_included
            content_for :header_tags do
              if User.current.wysiwyg_editing_preference :enabled
                javascript_include_tag('lib/undress',                :plugin => 'wysiwyg_editing') +
                javascript_include_tag('lib/tiny_mce/tiny_mce',      :plugin => 'wysiwyg_editing') +
                javascript_include_tag('app/tiny_mce_configuration', :plugin => 'wysiwyg_editing')
              else
                javascript_include_tag('jstoolbar/jstoolbar') +
                javascript_include_tag('jstoolbar/textile') +
                javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}") +
                stylesheet_link_tag('jstoolbar')
              end
            end
            @heads_for_wiki_formatter_included = true
          end
        end
      end
    end
  end
end