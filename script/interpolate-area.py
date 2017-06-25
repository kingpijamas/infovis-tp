import pdb
import argparse
import csv
import itertools as it
import numpy as np
from operator import attrgetter
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

    def group_by(data, keyfunc):
        data = sorted(data, key=keyfunc)
        return {k: list(group) for k, group in it.groupby(data, keyfunc)}

    def load_readings(monitors_path, readings_path):
        monitors = group_by(load_csv(monitors_path, Monitor), attrgetter('id'))
        chem_readings = group_by(load_csv(readings_path, ChemReading), attrgetter('date_time'))

        return {
            time: map(associate_monitor(monitors), )
            for time, chem_readings_for_time
            in chem_readings
        }

    def associate_monitor(monitors):
        def _associate(chem_readings):
            monitor = monitors[chem_reading.monitor_id]
            return RawReading(x=float(monitor.x), y=float(monitor.y), value=float(reading.value))

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

        return parser.parse_args()

    args = parse_raw_args()
    readings = load_readings(args.monitors, args.readings[0])

    return Point(*args.start), Point(*args.end), readings


start_point, end_point, readings = parse_args()
reading_positions, reading_values = readings[:, [0, 1]], readings[:, 2]
value_interpolation = LinearNDInterpolator(reading_positions, reading_values)

xs = np.array(range(start_point.x, end_point.x))
ys = np.array(range(start_point.y, end_point.y))

interpolated_values = [
    (x, y, value_interpolation(x, y))
    for x, y in it.product(xs, ys)
]

# raw_xs = xrange(0, 10)
# values = np.array(map(lambda x: (x, x, x * x), raw_xs))
#
# interp = LinearNDInterpolator(values[:, [0, 1]], values[:, 2])


pdb.set_trace()

#
# with open('.csv', 'rb') as csvfile:
