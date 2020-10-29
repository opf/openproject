require 'active_support/concern'
require 'typed_dag/configuration'
require 'typed_dag/rebuild_dag'
require 'typed_dag/node/closure_maintenance'
require 'typed_dag/node/class_methods'
require 'typed_dag/node/instance_methods'
require 'typed_dag/node/associations'

module TypedDag::Node
  extend ActiveSupport::Concern

  included do
    include ClosureMaintenance
    include ClassMethods
    include InstanceMethods
    include Associations
    include ::TypedDag::RebuildDag
  end
end
