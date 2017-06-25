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

  def ==(other)
    # NOTE: this is really weird, but equality seems to be broken by something I added...
    # :/ fixing it this way
    super unless other.is_a? Factory
    to_a == other.to_a
  end
end
