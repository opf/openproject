module CodeRay
module Scanners

  map :cpp => :c,
    :plain => :plaintext,
    :pascal => :delphi,
    :irb => :ruby,
    :xml => :html,
    :xhtml => :nitro_xhtml,
    :nitro => :nitro_xhtml

  default :plain

end
end
