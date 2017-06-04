require_relative "dates"

ChemReading = Struct.new(:chemical, :raw_monitor, :raw_date_time, :raw_value) do
  include Comparable

  def date_time
    @date_time ||= Dates.date_from(raw_date_time)
  end

  def monitor
    @monitor ||= raw_monitor.to_i
  end

  def value
    @value ||= raw_value.to_f
  end

  def <=>(other)
    [monitor, date_time] <=> [other.monitor, other.date_time]
  end
end
