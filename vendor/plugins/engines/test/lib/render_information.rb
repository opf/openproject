#-- encoding: UTF-8
module RenderInformation
  def render_class_and_action(note = nil, options={})
    text = "rendered in #{self.class.name}##{params[:action]}"
    text += " (#{note})" unless note.nil?
    render options.update(:text => text)
  end
end