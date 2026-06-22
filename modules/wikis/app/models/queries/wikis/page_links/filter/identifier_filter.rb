# frozen_string_literal: true

#-- copyright
#++

module Queries
  module Wikis
    module PageLinks
      module Filter
        class IdentifierFilter < Filters::Base
          def type = :string

          def where
            operator_strategy.sql_for_field(values, ::Wikis::PageLink.table_name, "identifier")
          end
        end
      end
    end
  end
end
