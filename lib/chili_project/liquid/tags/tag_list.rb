module ChiliProject::Liquid::Tags
  class TagList < Tag
    include ActionView::Helpers::TagHelper

    def render(context)
      content_tag('p', "Tags:") +
      content_tag('ul',
        ::Liquid::Template.tags.keys.sort.collect {|tag_name|
          content_tag('li', content_tag('code', h(tag_name)))
        }.join('')
      )
    end
  end
end