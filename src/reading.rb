Reading = Struct.new(:chemical, :raw_monitor, :raw_date_time, :raw_value) do
  include Comparable

  def date_time
    @date_time ||= date_from(raw_date_time)
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

  private

  def date_from(raw_date_time, base_year = 2000)
    date_str, time_str        = raw_date_time.split(" ")
    month, day, relative_year = date_str.split("/").map(&:to_i)

    base_year -= 100 if relative_year > DateTime.now.year.to_s[-2..-1].to_i
    year          = base_year + relative_year
    hour, minutes = time_str.split(":").map(&:to_i)
    DateTime.new(year, month, day, hour, minutes)
  end
end
