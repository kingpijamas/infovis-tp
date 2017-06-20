require_relative "position"

ChemMonitor = Struct.new(:raw_id, :raw_x, :raw_y) do
  extend Forwardable

  def_delegators :position, *%i[x y distance_to]

  def self.all_from(rows)
    rows.map { |row| new(*row) }
  end

  def id
    @id ||= raw_id.to_i
  end

  def position
    @position ||= Position.new(raw_x, raw_y)
  end
end
