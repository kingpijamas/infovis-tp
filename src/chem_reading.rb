require "date"
require_relative "dates"

ChemReading = Struct.new(:chemical, :raw_monitor_id, :raw_date_time, :raw_value) do
  extend Forwardable
  include Comparable

  def_delegators :date_time, *%i[year month day wday]

  def self.all_from(rows)
    rows.map { |row| new(*row) }
  end

  def date_time
    @date_time ||= Dates.date_from(raw_date_time)
  end

  def month_name
    Date::ABBR_MONTHNAMES[month]
  end

  def day_name
    Date::ABBR_DAYNAMES[wday]
  end

  def monitor_id
    @monitor_id ||= raw_monitor_id.to_i
  end

  def value
    @value ||= raw_value.to_f
  end

  def <=>(other)
    [monitor_id, date_time] <=> [other.monitor_id, other.date_time]
  end
end
