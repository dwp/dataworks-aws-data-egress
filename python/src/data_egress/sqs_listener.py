from boto3.dynamodb.conditions import Key
import uuid
import requests
import base64
from Crypto.Cipher import AES
from Crypto.Util import Counter
import zlib
import logging
import re
import boto3

DATA_ENCRYPTION_KEY_ID = "datakeyencryptionkeyid"

CIPHER_TEXT = "ciphertext"

IV = "iv"

METADATA = "Metadata"

sqs_count = 0

PIPELINE_SUCCESS_FLAG = "pipeline_success.flag"
KEY_RECORDS = "Records"
KEY_S3 = "s3"
KEY_OBJECT = "object"
KEY_KEY = "key"
REGEX_PATTERN = r"^[\w\/-]*pipeline_success.flag$"
DATA_EGRESS_DYNAMO_DB_TABLE = "data-egress"
DYNAMO_DB_ITEM_SOURCE_BUCKET = "source_bucket"
DYNAMO_DB_ITEM_DESTINATION_BUCKET = "destination_bucket"
DYNAMO_DB_ITEM_SOURCE_PREFIX = "source_prefix"
DYNAMO_DB_ITEM_DESTINATION_PREFIX = "destination_prefix"
DYNAMO_DB_ITEM_TRANSFER_TYPE = "transfer_type"
S3_TRANSFER_TYPE = "s3"
keys_map = []


def receive_message_from_sqs():
    sqs_client = get_client(service_name="sqs")
    while True:
        sqs_count = sqs_count + 1
        response = sqs_client.get_queue_attributes(
            QueueUrl="string", AttributeNames=["ApproximateNumberOfMessages"]
        )
        available_msg_coumt = response["Attributes"]["ApproximateNumberOfMessages"]
        if available_msg_coumt and available_msg_coumt > 0:
            # TODO Recheck on the attribute names
            response = sqs_client.receive_message(
                QueueUrl="string",
                AttributeNames=["All"],
                MessageAttributeNames=["string",],
                MaxNumberOfMessages=123,
                VisibilityTimeout=123,
                WaitTimeSeconds=123,
                ReceiveRequestAttemptId="string",
            )
            s3_prefix = process_messages(response)
            records = query_dymodb(s3_prefix)
            process_dynamo_db_response(s3_prefix, records)


# TODO More than one message wil be received in a single batch
def process_messages(response):
    """Processes response received from listening to sqs.

     Arguments:
         response: Response received from sqs
     """
    s3_prefixes = []
    s3_keys = []
    try:
        records = response[KEY_RECORDS]
        for record in records:
            s3_key = record[KEY_S3][KEY_OBJECT][KEY_KEY]
            s3_keys.append(s3_key)
    except Exception as ex:
        logging.error(
            f"Key: {str(ex)} not found when retrieving the prefix from sqs message"
        )
        raise KeyError(
            f"Key: {str(ex)} not found when retrieving the prefix from sqs message"
        )
    for s3_key in s3_keys:
        if re.match(REGEX_PATTERN, s3_key):
            s3_prefix = s3_key.replace(PIPELINE_SUCCESS_FLAG, "")
            s3_prefixes.append(s3_prefix)
        else:
            logging.error(f"{s3_key} is not in the pattern {REGEX_PATTERN}")
    return s3_prefixes


def query_dymodb(s3_prefix):
    """Query  DynamoDb status table for a given correlation id.

    Arguments:
        s3_prefix (string): source bucket prefix to query dynamo db table
    """
    dynamodb_client = get_client(service_name="dynamodb")
    table = dynamodb_client.Table(DATA_EGRESS_DYNAMO_DB_TABLE)
    response = table.query(KeyConditionExpression=Key("source_prefix").eq(s3_prefix))
    return response["Items"]


def process_dynamo_db_response(s3_prefix, records):
    """Processes the dynamo db response

    Arguments:
    s3_prefix (string): source bucket prefix to query dynamo db table
    records: List of records found in dynamo db for the query
    """
    if len(records) == 0:
        raise Exception(f"No records found in dynamo db for the s3_prefix {s3_prefix}")
    elif len(records) > 1:
        raise Exception(f"More than 1 record for the s3_prefix {s3_prefix}")
    else:
        try:
            record = records[0]
            source_bucket = record[DYNAMO_DB_ITEM_SOURCE_BUCKET]
            source_prefix = record[DYNAMO_DB_ITEM_SOURCE_PREFIX]
            transfer_type = record[DYNAMO_DB_ITEM_TRANSFER_TYPE]
            if transfer_type == S3_TRANSFER_TYPE:
                destination_bucket = record[DYNAMO_DB_ITEM_DESTINATION_BUCKET]
                destination_prefix = record[DYNAMO_DB_ITEM_DESTINATION_PREFIX]
                start_processing(
                    source_bucket, source_prefix, destination_bucket, destination_prefix
                )
        except Exception as ex:
            logging.error(
                f"Key: {str(ex)} not found when retrieving from dynamodb response"
            )
            raise KeyError(
                f"Key: {str(ex)} not found when retrieving from dynamodb response"
            )


def start_processing(
    source_bucket, source_prefix, destination_bucket, destination_prefix
):
    s3_client = get_client(service="s3")
    keys = get_all_s3_keys(source_bucket, source_prefix)
    for key in keys:
        s3_object = s3_client.get_object(Bucket=source_bucket, Key=key)
        iv = s3_object[METADATA][IV]
        ciphertext = s3_object[METADATA][CIPHER_TEXT]
        datakeyencryptionkeyid = s3_object[METADATA][DATA_ENCRYPTION_KEY_ID]
        plain_text_key = get_plaintext_key_calling_dks(
            ciphertext, datakeyencryptionkeyid
        )
        streaming_data = s3_client.get_object(Bucket=source_bucket, Key=key)["Body"]
        decrypted_stream = decrypt(plain_text_key, iv, streaming_data)
        compress(decrypted_stream)
        credentials_dict = assume_role()
        boto3_session = boto3.session.Session(
            aws_access_key_id=credentials_dict["AccessKeyId"],
            aws_secret_access_key=credentials_dict["SecretAccessKey"],
            aws_session_token=credentials_dict["SessionToken"],
        )
        save(s3_client, "", destination_bucket, destination_prefix)


def get_all_s3_keys(source_bucket, source_prefix):
    s3_client = get_client(service="s3")
    keys = []
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=source_bucket, Prefix=source_prefix)
    for page in pages:
        for obj in page["Contents"]:
            keys.append(obj["Key"])
    return keys


def get_plaintext_key_calling_dks(encryptedkey, keyencryptionkeyid):
    if keys_map.get(encryptedkey):
        key = keys_map[encryptedkey]
    else:
        key = call_dks(encryptedkey, keyencryptionkeyid)
        keys_map[encryptedkey] = key
    return key


def call_dks(cek, kek):
    try:
        url = "${url}"
        params = {"keyId": kek}
        result = requests.post(
            url,
            params=params,
            data=cek,
            cert=(
                "/etc/pki/tls/certs/private_key.crt",
                "/etc/pki/tls/private/private_key.key",
            ),
            verify="/etc/pki/ca-trust/source/anchors/analytical_ca.pem",
        )
        content = result.json()
    except BaseException as ex:
        logging.error(f"Problem calling DKS {str(ex)}")
    return content["plaintextDataKey"]


def decrypt(plain_text_key, iv_key, data):
    try:
        iv_int = int(base64.b64decode(iv_key).hex(), 16)
        ctr = Counter.new(AES.block_size * 8, initial_value=iv_int)
        aes = AES.new(base64.b64decode(plain_text_key), AES.MODE_CTR, counter=ctr)
        decrypted = aes.decrypt(data)
    except BaseException as ex:
        logging.error(f"Problem decrypting data {str(ex)}")
    return decrypted


def compress(decrypted_stream):
    return zlib.compress(decrypted_stream, 16 + zlib.MAX_WBITS)


def save(s3_client, file_name, destination_bucket, destination_prefix):
    with open(file_name, "rb") as data:
        s3_client.upload_fileobj(
            data,
            destination_bucket,
            f"{destination_prefix}/{file_name}.enc",
            ExtraArgs={"Metadata": ""},
        )


def assume_role():
    """Assumes the role needed for the boto3 session.

    Keyword arguments:
    profile -- the profile name to use (if None, default profile is used)
    """
    global aws_role_arn
    global aws_session_timeout_seconds
    global boto3_session

    if aws_role_arn is None or aws_session_timeout_seconds is None:
        raise AssertionError("abc")

    session_name = "data_egress" + str(uuid.uuid4())
    sts_client = boto3_session.client("sts")
    assume_role_dict = {}
    # sts_client.assume_role(
    # RoleArn=aws_role_arn,
    # RoleSessionName=f"{session_name}",
    # DurationSeconds=int(aws_session_timeout_seconds)),

    return assume_role_dict["Credentials"]


def get_client(service_name):
    client = boto3.client(service_name)
    return client

if __name__ == "__main__":
    try:
        receive_message_from_sqs()
    except Exception as e:
        print("something")
