ActiveSupport.on_load :turbo_streams_tag_builder do
  def dialog(&)
    action(:dialog, nil, &)
  end

  def flash(&)
    action(:flash, nil, &)
  end
end
