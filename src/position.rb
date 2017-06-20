Position = Struct.new(:raw_x, :raw_y) do
  def self.all_from(rows)
    rows.map { |row| new(*row) }
  end

  def x
    @x ||= raw_x.to_i
  end

  def y
    @y ||= raw_y.to_i
  end

  def distance_to(other)
    Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2)
  end
end
