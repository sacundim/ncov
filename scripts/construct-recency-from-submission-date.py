import argparse
from datetime import datetime
from augur.io import read_metadata
import json
import re

def get_recency(date_str, ref_date):
    date_submitted = datetime.strptime(date_str, '%Y-%m-%d').toordinal()
    ref_day = ref_date.toordinal()

    delta_days = ref_day - date_submitted
    if delta_days<=0:
        return 'New'
    elif delta_days<3:
        return '1-2 days ago'
    elif delta_days<8:
        return '3-7 days ago'
    elif delta_days<15:
        return 'One week ago'
    elif delta_days<31:
        return 'One month ago'
    elif delta_days>=31:
        return 'Older'

def get_submission_lag(date_collected_str, date_submitted_str):
    date_collected = safe_parse_date_str(date_collected_str)
    date_submitted = safe_parse_date_str(date_submitted_str)
    if date_collected and date_submitted:
        submission_lag = date_submitted.toordinal() - date_collected.toordinal()
        if submission_lag >= 0:
            return submission_lag

def safe_parse_date_str(date_str):
    """Parse a string in YYYY-MM-DD format, or return None if it fails"""
    date_pattern = re.compile(r"^\d{4}-\d{2}-\d{2}$")
    if date_pattern.match(date_str):
        return datetime.strptime(date_str, '%Y-%m-%d')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Assign each sequence fields computed from its submission date",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--metadata', type=str, required=True, help="metadata file")
    parser.add_argument('--output', type=str, required=True, help="output json")
    args = parser.parse_args()

    meta = read_metadata(args.metadata)

    node_data = {'nodes':{}}
    ref_date = datetime.now()

    for strain, d in meta.iterrows():
        strain_data = {}
        if 'date_submitted' in d and d['date_submitted'] and d['date_submitted'] != "undefined":
            strain_data['recency'] = get_recency(d['date_submitted'], ref_date)

            if 'date' in d and d['date'] and d['date'] != "undefined":
                submission_lag = get_submission_lag(d['date'], d['date_submitted'])
                if submission_lag:
                    strain_data['submission_lag'] = submission_lag

        node_data['nodes'][strain] = strain_data

    with open(args.output, 'wt') as fh:
        json.dump(node_data, fh)
