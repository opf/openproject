class ErbseCell < Cell::ViewModel
  include Cell::Erb
  self.view_paths = ["test/dummy/app/cells"]

  def form(&block)
    @block = block
    nil
  end

  def render_block
    @block.call
  end
end
