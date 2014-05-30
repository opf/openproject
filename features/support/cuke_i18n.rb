module CukeI18n
  def translate(step)
    step.gsub(/t:[\w\.]+/) { |code| I18n.t(code.split(":").last) }
  end
end

World(CukeI18n)
