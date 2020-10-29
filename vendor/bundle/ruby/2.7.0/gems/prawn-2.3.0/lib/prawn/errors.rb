# frozen_string_literal: true

# errors.rb : Implements custom error classes for Prawn
#
# Copyright April 2008, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module Prawn
  module Errors
    # Raised when a table is spanned in an impossible way.
    #
    InvalidTableSpan = Class.new(StandardError)

    # This error is raised when a method requiring a current page is called
    # without being on a page.
    #
    NotOnPage = Class.new(StandardError)

    # This error is raised when Prawn cannot find a specified font
    #
    UnknownFont = Class.new(StandardError)

    # Raised when Prawn is asked to draw something into a too-small box
    #
    CannotFit = Class.new(StandardError)

    # Raised if group() is called with a block that is too big to be
    # rendered in the current context.
    #
    CannotGroup = Class.new(StandardError)

    # This error is raised when Prawn is being used on a M17N aware VM,
    # and the user attempts to add text that isn't compatible with UTF-8
    # to their document
    #
    IncompatibleStringEncoding = Class.new(StandardError)

    # This error is raised when Prawn encounters an unknown key in functions
    # that accept an options hash.  This usually means there is a typo in your
    # code or that the option you are trying to use has a different name than
    # what you have specified.
    #
    UnknownOption = Class.new(StandardError)

    # this error is raised when a user attempts to embed an image of an
    # unsupported type. This can either a completely unsupported format, or
    # a dialect of a supported format (ie. some types of PNG)
    UnsupportedImageType = Class.new(StandardError)

    # This error is raised when a named element has alredy been
    # created. For example, in the stamp module, stamps must have
    # unique names within a document
    NameTaken = Class.new(StandardError)

    # This error is raised when a name is not a valid format
    InvalidName = Class.new(StandardError)

    # This error is raised when an object is attempted to be
    # referenced by name, but no such name is associated with an object
    UndefinedObjectName = Class.new(StandardError)

    # This error is raised when a required option has not been set
    RequiredOption = Class.new(StandardError)

    # This error is raised when a requested outline item with a given title does
    # not exist
    UnknownOutlineTitle = Class.new(StandardError)

    # This error is raised when a block is required, but not provided
    BlockRequired = Class.new(StandardError)

    # This error is rased when a graphics method is called with improper
    # arguments
    InvalidGraphicsPath = Class.new(StandardError)

    # Raised when unrecognized content is provided for a table cell.
    #
    UnrecognizedTableContent = Class.new(StandardError)

    # This error is raised when an incompatible join style is specified
    InvalidJoinStyle = Class.new(StandardError)
  end
end
