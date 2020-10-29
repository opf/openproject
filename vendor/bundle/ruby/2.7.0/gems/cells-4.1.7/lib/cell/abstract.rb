module Cell::Abstract
  def abstract!
    @abstract = true
  end

  def abstract?
    @abstract
  end
end