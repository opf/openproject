class TypedDag::Engine < ::Rails::Engine
  config.to_prepare do
    TypedDag::Configuration.each do |instance|
      instance.edge_class_name.constantize.send(:include, TypedDag::Edge)

      instance.node_class_name.constantize.send(:include, TypedDag::Node)
    end
  end
end
