class TypedDag::Configuration
  def self.set(config)
    config = [config] unless config.is_a?(Array)

    @instances = config.map { |conf| new(conf) }
  end

  def self.[](class_name)
    class_name = class_name.to_s

    @instances.detect do |config|
      config.node_class_name == class_name ||
        config.edge_class_name == class_name
    end
  end

  def self.each
    @instances.each do |instance|
      yield instance
    end
  end

  def initialize(config)
    self.config = config
  end

  def node_class_name
    config[:node_class_name]
  end

  def node_class
    node_class_name.constantize
  end

  def node_table_name
    node_class.table_name
  end

  def edge_class_name
    config[:edge_class_name]
  end

  def edge_class
    edge_class_name.constantize
  end

  def edge_table_name
    edge_class.table_name
  end

  def from_column
    config[:from_column] || 'from_id'
  end

  def to_column
    config[:to_column] || 'to_id'
  end

  def count_column
    config[:count_column] || 'count'
  end

  def types
    config[:types] || default_types
  end

  def type_columns
    types.keys
  end

  private

  attr_accessor :config

  def default_types
    { hierarchy: { from: { name: :parent, limit: 1 },
                   to: :children,
                   all_from: :ancestors,
                   all_to: :descendants } }
  end
end
