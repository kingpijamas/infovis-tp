#!/usr/bin/ruby

require "csv"
require "fileutils"
require "pry"

INPUT_FILE             = ARGV.shift
MAX_REFINING_RUNS      = ARGV.shift.to_i || 2
OUTPUT_DIR             = "data/processed"
STDDEVS_TO_BE_ATYPICAL = 1

class DataRefiner
  def refine(path)
    csv_headers, *csv_rows = CSV.read(path)
    readings               = csv_rows.map { |row| Reading.new(*row) }
    readings_by_chemical   = readings.group_by(&:chemical)

    readings_by_chemical.each do |(_, readings_for_chemical)|
      refined_readings_for_chemical = refine_readings(readings_for_chemical)
      errored_readings_for_chemical = refine_readings(refined_readings_for_chemical.atypical).atypical
      refined_readings_for_chemical.atypical -= errored_readings_for_chemical

      store_readings(csv_headers, refined_readings_for_chemical, errored_readings_for_chemical)
      print "."
    end

    print "\n"
  end

  private

  def refine_readings(readings)
    prev_readings = readings = RefinedReadings.from(readings)
    return readings if readings.atypical.empty?

    (MAX_REFINING_RUNS - 1).times do
      prev_readings = readings
      readings      = RefinedReadings.from(readings)
      return readings if readings.atypical.count == prev_readings.atypical.count
    end
    readings
  end

  def store_readings(headers, valid_readings, errored_readings)
    %i[normal atypical errored].each do |reading_type|
      file_name = "#{OUTPUT_DIR}/#{valid_readings.chemical.downcase}-#{reading_type}.csv"

      CSV.open(file_name, "w") do |csv_file|
        csv_file << headers

        sorted_readings =
          if reading_type == :errored
            errored_readings
          else
            valid_readings.public_send(reading_type).sort
          end

        sorted_readings.each { |reading| csv_file << reading.to_a }
      end
    end
  end

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

  RefinedReadings = Struct.new(:normal, :atypical) do
    class << self
      def from(readings)
        case readings
        when Array
          from_array(readings)
        when RefinedReadings
          from_refined(readings)
        end
      end

      def from_array(readings)
        readings_stats        = Stats.from(readings, :value)
        readings_by_normality = readings.group_by { |reading| readings_stats.normal?(reading.value) }

        new(
          normal:   readings_by_normality.fetch(true, []),
          atypical: readings_by_normality.fetch(false, [])
        )
      end

      def from_refined(readings)
        refined_readings = from_array(readings.normal)

        new(
          normal:   refined_readings.normal,
          atypical: refined_readings.atypical + readings.atypical
        )
      end
    end

    def initialize(**kwargs)
      super(*members.map { |attr| kwargs.fetch(attr) })
    end

    def chemical
      return unless reading = (normal.first || atypical.first)
      reading.chemical
    end
  end

  Stats = Struct.new(:avg, :stddev) do
    class << self
      def from(values, attr = nil)
        values  = values.map(&attr) if attr
        average = avg(values)
        new(average, stddev(values, average))
      end

      def sum(values, &block)
        block ||= Proc.new { |value| value }
        values.inject(0) { |result, value| result + block[value] }
      end

      def avg(values)
        return 0.0 if values.empty?
        sum(values) / values.length.to_f
      end

      def stddev(values, average = nil)
        return 0.0 if values.length <= 1
        average ||= avg(values)

        values_sum = sum(values) { |value| (value - average)**2 }
        Math.sqrt(values_sum / values.length.to_f)
      end
    end

    def normal?(value)
      (value - avg).abs <= stddev * STDDEVS_TO_BE_ATYPICAL
    end
  end
end

FileUtils.mkdir_p OUTPUT_DIR
DataRefiner.new.refine(INPUT_FILE)
