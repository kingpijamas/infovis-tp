import pdb
import argparse
import csv
import itertools as it
import numpy as np
from collections import namedtuple
from scipy.interpolate import LinearNDInterpolator

Point = namedtuple('Point', ['x', 'y'])
Monitor = namedtuple('Monitor', ['id', 'x', 'y'])
ChemReading = namedtuple('Reading', ['chemical', 'monitor_id', 'date_time', 'value'])
RawReading = namedtuple('Reading', ['x', 'y', 'value'])

def parse_args():
    def load_csv(path, type):
        with open(path, 'rb') as csvfile:
            return [
                type(*line.rstrip().split(','))
                for idx, line in enumerate(csvfile)
                if idx > 0
            ]

    def load_readings(monitors_path, readings_path):
        monitors = load_csv(monitors_path, Monitor)
        readings = load_csv(readings_path, ChemReading)

        return np.array([
            RawReading(float(reading.value), float(monitor.x), float(monitor.y))
            for reading, monitor
            in it.product(readings, monitors)
            if reading.monitor_id == monitor.id
        ])

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

        return parser.parse_args()

    args = parse_raw_args()
    readings = load_readings(args.monitors, args.readings[0])

    return Point(*args.start), Point(*args.end), readings


start_point, end_point, readings = parse_args()
reading_positions, reading_values = readings[:, [1, 2]], readings[:, 0]
value_interpolation = LinearNDInterpolator(reading_positions, reading_values)

xs = np.array(range(start_point.x, end_point.x))
ys = np.array(range(start_point.y, end_point.y))

interpolated_values = [
    (x, y, value_interpolation(x, y))
    for x, y in it.product(xs, ys)
]

pdb.set_trace()

#
# with open('.csv', 'rb') as csvfile:
