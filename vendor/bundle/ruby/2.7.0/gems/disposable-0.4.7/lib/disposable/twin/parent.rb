module Disposable::Twin::Parent
  def self.included(includer)
    includer.class_eval do
      property(:parent, virtual: true)
    end
  end

  # FIXME: for collections, this will merge options for every element.
  def build_twin(dfn, value, options={})
    super(dfn, value, options.merge(parent: self))
  end
end
