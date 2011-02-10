module CodeRay
module Scanners

  load :html

  # XML Scanner
  #
  # Currently this is the same scanner as Scanners::HTML.
  class XML < HTML

    register_for :xml
    file_extension 'xml'
    
  end

end
end
