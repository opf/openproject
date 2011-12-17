module ChiliProject::Liquid::Tags
  class Identity < Tag
    def initialize(tag_name, markup, tokens)
      @tag_name = tag_name
      @markup = markup
      @tokens = tokens
      super
    end

    def render(context)
      "{% #{@tag_name} %}"
    end
  end
end