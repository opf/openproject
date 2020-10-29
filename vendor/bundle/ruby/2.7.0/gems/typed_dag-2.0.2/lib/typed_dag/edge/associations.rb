module TypedDag::Edge
  module Associations
    extend ActiveSupport::Concern

    included do
      belongs_to :from,
                 class_name: _dag_options.node_class_name,
                 foreign_key: _dag_options.from_column
      belongs_to :to,
                 class_name: _dag_options.node_class_name,
                 foreign_key: _dag_options.to_column
    end
  end
end
