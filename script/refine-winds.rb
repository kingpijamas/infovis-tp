#!/usr/bin/ruby

require "pry"
require "csv"
require "fileutils"

require_relative "../src/script_params"
require_relative "../src/wind_reading"

params = ScriptParams.read!(
  {
    name:    "from",
    attr:    "input_file"
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

INPUT_FILE  = params.fetch(:input_file)
OUTPUT_DIR  = params.fetch(:output_dir)
OUTPUT_FILE = params.fetch(:output_file)

class WindRefiner
  WIND_READING_ATTRS_COUNT = WindReading.members.count - 1

  def refine(file_path)
    csv_headers, *csv_rows = CSV.read(file_path).each_with_object([]) do |csv_row, result|
      relevant_values = csv_row[0..WIND_READING_ATTRS_COUNT]
      result << relevant_values if relevant_values.any?
    end

    readings = WindReading.all_from(csv_rows)

    store_readings(csv_headers, readings)
  end

  private

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
