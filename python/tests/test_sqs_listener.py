from data_egress import sqs_listener
import json

def test_process_message():
    json_file = open('/Users/udaykiranchokkam/DWP-Workspace/dataworks-aws-data-egress/python/tests/sqs_message.json')
    response = json.load(json_file)
    s3_prefix = sqs_listener.process_message(response)
    assert s3_prefix == 'data-egress-testing/2021-01-10'
