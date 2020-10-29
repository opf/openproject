module Warning
  KERNEL_WARN = Kernel.instance_method(:warn).bind(self)

  def warn(*args)
    KERNEL_WARN.call(*args)
  end

  extend self
end
