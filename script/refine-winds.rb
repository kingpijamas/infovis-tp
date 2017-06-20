#!/usr/bin/ruby

require "pry"
require "csv"
require "fileutils"
require "interpolate"

require_relative "../src/script_params"
require_relative "../src/wind_reading"
require_relative "../src/chem_reading"

def read_rows(klass)
  -> (file_name) do
    _headers, *rows = CSV.read(file_name)
    klass.all_from(rows)
  end
end

params = ScriptParams.read!(
  {
    name:    "from",
    attr:    "input_file"
  },
  {
    name:    "interpolate-to-chems",
    attr:    "chems",
    cast:    read_rows(ChemReading),
    default: []
  },
  {
    name:    "output-dir",
    default: "data/processed"
  },
  {
    name:    "output-file",
    default: "winds.csv"
  }
)

INPUT_FILE              = params.fetch(:input_file)
OUTPUT_DIR              = params.fetch(:output_dir)
OUTPUT_FILE             = params.fetch(:output_file)
CHEMS_TO_INTERPOLATE_TO = params.fetch(:chems)

class WindRefiner
  WIND_READING_ATTRS_COUNT = WindReading.members.count - 1

  def refine(file_path)
    csv_headers, *csv_rows = CSV.read(file_path).each_with_object([]) do |csv_row, result|
      relevant_values = csv_row[0..WIND_READING_ATTRS_COUNT]
      result << relevant_values if relevant_values.any?
    end

    readings = WindReading.all_from(csv_rows)

    if CHEMS_TO_INTERPOLATE_TO.any?
      wind_interpolator = WindInterpolator.from(readings, CHEMS_TO_INTERPOLATE_TO)
      readings += wind_interpolator.wind_interpolations
      readings.uniq!(&:date_time).sort!
    end

    store_readings(csv_headers, readings)
  end

  private

  class WindInterpolator < Struct.new(:base_time, :wind_interpolation, :chem_readings)
    def self.from(wind_readings, chem_readings)
      chem_readings = chem_readings.uniq(&:date_time)
      base_time     = (wind_readings + chem_readings).map(&:date_time).min

      interpolation_reference = wind_readings.each_with_object({}) do |wind_reading, result|
        seconds_from_base_time         = Dates.seconds_between(wind_reading.date_time, base_time)
        from_direction                 = wind_reading.from_direction
        speed                          = wind_reading.speed
        result[seconds_from_base_time] = [from_direction, speed]
      end

      new(
        base_time:          base_time,
        wind_interpolation: Interpolate::Points.new(interpolation_reference),
        chem_readings:      chem_readings
      )
    end

    def initialize(**kwargs)
      super(*members.map { |attr| kwargs.fetch(attr) })
    end

    def wind_interpolations
      chem_readings.map do |chem_reading|
        seconds_from_base_time = Dates.seconds_between(chem_reading.date_time, base_time)
        date_time              = Dates.add_seconds(base_time, seconds_from_base_time)
        from_direction, speed  = wind_interpolation.at(seconds_from_base_time)

        WindReading.new(Dates.format(date_time), from_direction, speed)
      end
    end
  end

  def store_readings(headers, readings)
    sorted_readings = readings.sort

    CSV.open("#{OUTPUT_DIR}/#{OUTPUT_FILE}", "w") do |csv_file|
      csv_file << headers
      sorted_readings.each { |reading| csv_file << reading.to_a }
    end
  end
end

FileUtils.mkdir_p OUTPUT_DIR
WindRefiner.new.refine(INPUT_FILE)
