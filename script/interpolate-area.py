import pdb
import argparse
import csv
import itertools as it
import numpy as np
import sys
import math
import os
from operator import attrgetter
from collections import namedtuple
from scipy.interpolate import LinearNDInterpolator
from scipy.spatial.qhull import QhullError
from datetime import datetime

Point = namedtuple('Point', ['x', 'y'])
Monitor = namedtuple('Monitor', ['id', 'x', 'y'])
ChemReading = namedtuple('ChemReading', ['chemical', 'monitor_id', 'date_time', 'value'])
RawReading = namedtuple('RawReading', ['x', 'y', 'value'])
ParsedArgs = namedtuple('ParsedArgs', ['output_dir', 'start_point', 'end_point', 'readings_by_time'])

def parse_args():
    def load_csv(path, type):
        with open(path, 'rb') as csvfile:
            return [
                type(*line.rstrip().split(','))
                for idx, line in enumerate(csvfile)
                if idx > 0
            ]

    def group_by(data, keyfunc):
        data = sorted(data, key=keyfunc)
        return {k: list(group) for k, group in it.groupby(data, keyfunc)}

    def load_readings(monitors_path, readings_path):
        monitors = group_by(load_csv(monitors_path, Monitor), attrgetter('id'))
        chem_readings = group_by(load_csv(readings_path, ChemReading), attrgetter('date_time'))
        # lengths = [len(v) for v in chem_readings.values()]
        # pdb.set_trace()
        _associate_monitor = associate_monitor(monitors)

        return {
            time: map(_associate_monitor, chem_readings_for_time)
            for time, chem_readings_for_time
            in chem_readings.iteritems()
        }

    def associate_monitor(monitors_by_id):
        def _associate(chem_reading):
            monitor = monitors_by_id[chem_reading.monitor_id][0]
            return RawReading(x=float(monitor.x), y=float(monitor.y), value=float(chem_reading.value))

        return _associate

    def parse_raw_args():
        parser = argparse.ArgumentParser(
            description='Interpolate chemicals over area')
        parser.add_argument('--start', metavar='x0',
                            type=int, nargs=2, required=True)
        parser.add_argument('--end', metavar='x1', type=int,
                            nargs=2, required=True)
        parser.add_argument('--monitors', metavar='path/to/monitors.csv',
                            nargs=1, default='data/processed/monitors.csv')
        parser.add_argument('--readings', metavar='path/to/readings.csv',
                            nargs=1, required=True)
        parser.add_argument('--output_dir', metavar='path/to/readings.csv',
                            nargs=1, required=True)

        return parser.parse_args()

    args = parse_raw_args()
    readings_by_time = load_readings(args.monitors, args.readings[0])

    return ParsedArgs(
        output_dir=args.output_dir[0],
        start_point=Point(*args.start),
        end_point=Point(*args.end),
        readings_by_time=readings_by_time
    )

def interpolate(start_point, end_point, readings_by_time):
    def generate_interpolation(reading_positions, reading_values):
        interpolation = LinearNDInterpolator(reading_positions, reading_values)

        def _interpolation(x, y):
            return float(interpolation(x, y))

        return _interpolation

    def _interpolate(readings):
        # Needed to be able to interpolate
        if len(readings) < 4:
            return readings

        readings = np.array(readings)
        reading_positions, reading_values = readings[:, [0, 1]], readings[:, 2]
        value_interpolation = generate_interpolation(reading_positions, reading_values)

        xs = np.array(range(start_point.x, end_point.x))
        ys = np.array(range(start_point.y, end_point.y))

        return [
            (x, y, value_interpolation(x, y))
            for x, y
            in it.product(xs, ys)
            if not math.isnan(value_interpolation(x, y))
        ]

    return {
        time: _interpolate(readings_for_time)
        for time, readings_for_time
        in readings_by_time.iteritems()
    }

def store_values(output_dir, values):
    def parse_time(raw_date_time):
        return datetime.strptime(raw_date_time, '%m/%d/%y %H:%M')

    def _store_values(filename, headers, values_for_time):
        with open(filename, 'wb') as csvfile:
            writer = csv.writer(csvfile, delimiter=',')

            writer.writerow(headers)

            for value in values_for_time:
                writer.writerow(value)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    first_time = min([parse_time(time) for time in values.keys()])

    for time, values_for_time in values.iteritems():
        hours_delta = int((parse_time(time) - first_time).total_seconds() / 3600)
        filename = '{output_dir}/{hours_delta}.csv'.format(output_dir=output_dir, hours_delta=hours_delta)

        _store_values(filename, ['x', 'y', 'reading'], values_for_time)

parsed_args = parse_args()
values = interpolate(parsed_args.start_point, parsed_args.end_point, parsed_args.readings_by_time)
store_values(parsed_args.output_dir, values)
