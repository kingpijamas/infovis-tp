require_relative "dates"

WindReading = Struct.new(:raw_date_time, :raw_from_direction, :raw_speed) do
  include Comparable

  def date_time
    @date_time ||= Dates.date_from(raw_date_time)
  end

  def from_direction
    @from_direction ||= raw_from_direction.to_f
  end

  def to_direction
    @to_direction ||= raw_from_direction * -1
  end

  def speed
    @speed ||= raw_speed.to_f
  end

  def <=>(other)
    date_time <=> other.date_time
  end
end
