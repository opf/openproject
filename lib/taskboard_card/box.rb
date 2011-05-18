module TaskboardCard
  class Box
    attr_accessor :x
    attr_accessor :y
    attr_accessor :width
    attr_accessor :height

    def initialize(x,y,w,h)
      @x = x
      @y = y
      @width = w
      @height = h
    end

    def at
      [x, y]
    end

    def at=(pos)
      x = pos[0]
      y = pos[1]
    end
  end
end