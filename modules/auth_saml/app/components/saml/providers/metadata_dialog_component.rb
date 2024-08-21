module Saml
  module Providers
    class MetadataDialogComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      alias_method :provider, :model

      def id
        "saml-metadata-dialog"
      end
    end
  end
end
