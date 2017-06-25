require_relative "dates"
require_relative "position"

WindReading = Struct.new(:raw_date_time, :raw_from_direction, :raw_speed) do
  include Comparable

  def self.all_from(rows)
    rows.map { |row| new(*row) }
  end

  def date_time
    @date_time ||= Dates.date_from(raw_date_time)
  end

  def from_direction
    @from_direction ||= raw_from_direction.to_f
  end

  def to_direction
    @to_direction ||= from_direction * -1
  end

  def speed
    @speed ||= raw_speed.to_f
  end

  def origin(position, lookback)
    Position.new(
      position.x - speed * lookback * Math.sin(to_direction),
      position.y - speed * lookback * Math.cos(to_direction)
    )
  end

  def <=>(other)
    date_time <=> other.date_time
  end

  def ==(other)
    # NOTE: this is really weird, but equality seems to be broken by something I added...
    # :/ fixing it this way
    super unless other.is_a? WindReading
    to_a == other.to_a
  end
end
