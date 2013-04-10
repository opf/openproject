module OpenProject::Backlogs::Compatibility
  def using_jquery?
    OpenProject::Compatibility.respond_to?(:using_jquery?) and
      OpenProject::Compatibility.using_jquery?
  rescue NameError
    false
  end

  extend self
end
