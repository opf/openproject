module Backlogs::Compatibility
  def using_jquery?
    ChiliProject::Compatibility.respond_to?(:using_jquery?) and
      ChiliProject::Compatibility.using_jquery?
  rescue NameError
    false
  end

  extend self
end
