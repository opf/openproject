module CodeRay
module Scanners

  load :html

  # XML Scanner
  #
  # $Id$
  #
  # Currently this is the same scanner as Scanners::HTML.
  class XML < HTML

    register_for :xml

  end

end
end
