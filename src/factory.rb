require_relative "position"

Factory = Struct.new(:name, :raw_x, :raw_y) do
  extend Forwardable

  def_delegators :position, *%i[x y distance_to]

  def self.all_from(rows)
    rows.map { |row| new(*row) }
  end

  def position
    @position ||= Position.new(raw_x, raw_y)
  end
end
