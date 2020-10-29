
# frozen_string_literal: true

module PDF
  module Core
    # This is used to differentiate strings that must be encoded as
    # a *literal* string, versus those that can be encoded in
    # the PDF hexadecimal format.
    #
    # Some features of the PDF format appear to require that literal
    # strings be used. One such feature is the /Dest key of a link
    # annotation; if a hex encoded string is used there, the links
    # do not work (as tested in Mac OS X Preview, and Adobe Acrobat
    # Reader).
    class LiteralString < String #:nodoc:
    end
  end
end
