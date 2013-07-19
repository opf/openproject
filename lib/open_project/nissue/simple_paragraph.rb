class OpenProject::Nissue::SimpleParagraph < OpenProject::Nissue::Paragraph
  def initialize(identifier, &block)
    @identifier = identifier
    @block = block
  end

  def label(t = nil)
    super || Issue.human_attribute_name(@identifier)
  end

  def visible?
    !!@block
  end

  def render(t)
    @block.call(t)
  end
end
