#!/usr/bin/ruby

require "pry"
require "csv"
require "fileutils"

require_relative "../src/script_params"
require_relative "../src/chem_reading"

params = ScriptParams.read!(
  {
    name:    "from",
    attr:    "input_dir",
    default: "data/processed/chems"
  },
  {
    name:    "type",
    attr:    "reading_types",
    default: [:very_atypical],
    cast:    -> (raw_types) { Array(raw_types).map(&:to_sym) }
  },
  {
    name:    "output-dir",
    default: "data/processed/monitor-errors"
  }
)

INPUT_DIR     = params.fetch(:input_dir)
OUTPUT_DIR    = params.fetch(:output_dir)
READING_TYPES = params.fetch(:reading_types)

class ChemDataMerger
  def merge(path)
    csv_headers, readings = readings_in(path, READING_TYPES)
    readings_by_monitor   = readings.group_by(&:monitor_id)

    readings_by_monitor.each do |(monitor_id, readings_for_monitor)|
      store_monitor_readings(csv_headers, readings_for_monitor)
    end
  end

  private

  def readings_in(dir, types)
    csv_headers = nil

    readings = types.flat_map do |type|
      Dir["#{dir}/*-#{type}.csv"].flat_map do |file_name|
        csv_headers, *csv_rows = CSV.read(file_name)
        ChemReading.all_from(csv_rows)
      end
    end

    [csv_headers, readings]
  end

  def store_monitor_readings(csv_headers, monitor_readings)
    sorted_readings = monitor_readings.sort(&method(:sort_readings))

    CSV.open("#{OUTPUT_DIR}/monitor-#{monitor_readings.first.monitor_id}.csv", "w") do |csv_file|
      csv_file << csv_headers if csv_headers
      sorted_readings.each { |reading| csv_file << reading.to_a }
    end
  end

  def sort_readings(reading_a, reading_b)
    comp = reading_a.chemical <=> reading_b.chemical
    return comp if comp != 0

    reading_a <=> reading_b
  end
end

FileUtils.mkdir_p OUTPUT_DIR
ChemDataMerger.new.merge(INPUT_DIR)
