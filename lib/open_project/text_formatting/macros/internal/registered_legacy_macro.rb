
module OpenProject::TextFormatting::Macros::Internal
  require 'open_project/text_formatting/macros/internal/registered_macro'
  # Wrapper for legacy macro classes
  # that we must get rid of once legacy macros have been eliminated
  class RegisteredLegacyMacro < RegisteredMacro
    require 'open_project/text_formatting/macros/internal/legacy_macro_class_factory'

    def initialize(id, desc, block)
      super LegacyMacroClassFactory.create_new_class id, desc, block
    end
  end
end
