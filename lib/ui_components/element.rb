module UiComponents
  class Element
    include Renderable
    include Accessible

    attr_accessor :output_buffer, :content

    # global attributes (HTML5)
    attr_accessor :css, :id, :accesskey,
                  :contenteditable,
                  :contextmenu,
                  :data,
                  :dir,
                  :draggable,
                  :dropzone,
                  :hidden,
                  :id,
                  :lang,
                  :spellcheck,
                  :style,
                  :tabindex,
                  :title,
                  :translate

    delegate :key_for, to: OpenProject::AccessKeys

    def initialize(attributes = {})
      @strategy = attributes.fetch :strategy, default_strategy
      @content = attributes.fetch :content, ''
      @css = attributes.fetch :class, nil
      tag attributes
    end

    protected

    def tag(attributes = {})
      {
        accesskey: nil,
        contenteditable: nil,
        contextmenu: nil,
        data: {},
        dir: nil,
        draggable: nil,
        dropzone: nil,
        hidden: nil,
        id: nil,
        lang: nil,
        spellcheck: nil,
        style: nil,
        tabindex: nil,
        title: nil,
        translate: nil
      }.each_pair do |var, default|
        assign var, attributes.fetch(var, default)
      end
    end

    def tag_attributes
      {
        accesskey: determine_accesskey,
        contenteditable: contenteditable,
        contextmenu: @contextmenu,
        data: @data,
        dir: @dir,
        draggable: @draggable,
        dropzone: @dropzone,
        id: @id,
        lang: @lang,
        spellcheck: @spellcheck,
        style: @style,
        tabindex: @tabindex,
        title: @title,
        translate: determine_translate
      }.merge(accessible_attributes)
    end

    def determine_accesskey
      return key_for(@accesskey) if @accesskey.is_a? Symbol
      return key_for(@accesskey.to_sym) if @accesskey.is_a? String
      @accesskey
    end

    def determine_translate
      return nil if @translate.nil?
      return :yes if translate
      :no
    end

    def css_classes
      @css.nil? ? [] : Array(@css)
    end

    def html_options
      return tag_attributes if css_classes.empty?
      tag_attributes.merge(class: css_classes)
    end

    def default_strategy
      -> {
        content_tag :div, @content, html_options
      }
    end

    def assig(var, value)
      send("#{var}=", value)
    end
  end
end
