module TypedDag::Node
  module InstanceMethods
    extend ActiveSupport::Concern

    def in_closure?(other_node)
      from_edge(other_node)
        .or(to_edge(other_node))
        .exists?
    end

    def from_edge(other_node)
      ancestors_relations
        .where(_dag_options.edge_table_name => { _dag_options.from_column => other_node })
    end

    def to_edge(other_node)
      descendants_relations
        .where(_dag_options.edge_table_name => { _dag_options.to_column => other_node })
    end

    def _dag_options
      self.class._dag_options
    end

    included do
      _dag_options.types.each do |key, config|
        from_one_limited = config[:from].is_a?(Hash) && config[:from][:limit] == 1
        from_name = if config[:from].is_a?(Hash)
                      config[:from][:name]
                    else
                      config[:from]
                    end

        define_method :"#{config[:all_to]}_of_depth" do |depth|
          send(config[:all_to])
            .where(_dag_options.edge_table_name => { key => depth })
        end

        define_method :"#{config[:all_from]}_of_depth" do |depth|
          send(config[:all_from])
            .where(_dag_options.edge_table_name => { key => depth })
        end

        define_method :"self_and_#{config[:all_from]}" do
          froms_scope = self.class.where(id: send(config[:all_from]))
          self_scope = self.class.where(id: id)

          froms_scope.or(self_scope)
        end

        define_method :"self_and_#{config[:all_to]}" do
          to_scope = self.class.where(id: send(config[:all_to]))
          self_scope = self.class.where(id: id)

          to_scope.or(self_scope)
        end

        define_method :"#{key}_leaves" do
          send(config[:all_to])
            .where(id: self.class.send("#{key}_leaves"))
        end

        define_method :"#{key}_leaf?" do
          send(:"#{config[:to]}_relations").empty?
        end

        define_method :"#{config[:to].to_s.singularize}?" do
          if from_one_limited
            !!send(:"#{from_name}_relation")
          else
            send(:"#{from_name}_relations").any?
          end
        end

        define_method :"#{from_name.to_s.singularize}?" do
          send(:"#{config[:to]}_relations").any?
        end

        define_method :"#{key}_roots" do
          send(config[:all_from])
            .where(id: self.class.send("#{key}_roots"))
        end

        define_method :"#{key}_root?" do
          if from_one_limited
            send(:"#{from_name}_relation").nil?
          else
            send(:"#{from_name}_relations").empty?
          end
        end
      end
    end
  end
end
