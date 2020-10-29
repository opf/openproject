module StructuredWarnings::Kernel
  def warn(*args)
    Warning.warn(*args)
  end
end

Object.class_eval { include StructuredWarnings::Kernel }
