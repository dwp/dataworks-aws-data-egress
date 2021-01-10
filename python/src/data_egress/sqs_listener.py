from data_egress import aws_helper
import boto3
from boto3.dynamodb.conditions import Key
import uuid
import requests
import base64
from Crypto.Cipher import AES
from Crypto.Util import Counter
import zlib

sqs_count = 0


def receive_message_from_sqs():
    sqs_client = aws_helper.get_client(service_name="sqs")
    while True:
        sqs_count = sqs_count + 1
        response = client.get_queue_attributes(
            QueueUrl='string',
            AttributeNames=['ApproximateNumberOfMessages']
        )
        available_msg_coumt = response['Attributes']['ApproximateNumberOfMessages']
        if available_msg_coumt and available_msg_coumt > 0:
            # TODO Recheck on the attribute names
            response = sqs_client.receive_message(
                QueueUrl='string',
                AttributeNames=['All'],
                MessageAttributeNames=[
                    'string',
                ],
                MaxNumberOfMessages=123,
                VisibilityTimeout=123,
                WaitTimeSeconds=123,
                ReceiveRequestAttemptId='string'
            )
            s3_prefix =  process_message(response)
            query_dymodb(s3_prefix)


def process_message(response):
    s3_key = response['Records'][0]['s3']['object']['key']
    if 'pipeline_success.flag' in s3_key:
        s3_prefix = s3_key.rsplit('/', 1)[0]
        return s3_prefix


def query_dymodb(s3_prefix):
    """Query  DynamoDb status table for a given correlation id.

    Arguments:
        dynamodb (client): The boto3 client for Dynamodb
        ddb_status_table (string): The name of the Dynamodb status table
        correlation_id (string): String value of correlation-id, originates from SNS
    """
    dynamodb_client = aws_helper.get_client(service_name="dynamodb")
    table = dynamodb_client.Table('')
    response = table.query(
        KeyConditionExpression=Key("source_prefix").eq(s3_prefix)
    )
    records = response["Items"]
    process_dynamo_db_response(records)


def process_dynamo_db_response(records):
    if len(records) == 0:
        print("")
        # raise Exception(
        #     f""
        # )
    # TODO Can it be more than one match?
    for item in records:
        source_bucket = item['source_bucket']
        destination_bucket = item['destination_bucket']
        source_prefix = item['source_prefix']
        destination_prefix = item['destination_prefix']
        transfer_type = item['transfer_type']
        if transfer_type == 's3':
            start_processing(source_bucket, source_prefix, destination_bucket, destination_prefix)

# Assume role , read, decrypt and compress if needed
def start_processing(source_bucket, source_prefix, destination_bucket, destination_prefix):

    read_and_write(source_bucket, source_prefix, destination_bucket, destination_prefix)


def compress(decrypted_stream):
        return zlib.compress(decrypted_stream, 16 + zlib.MAX_WBITS)


def read_and_write(source_bucket, source_prefix, destination_bucket, destination_prefix):
    s3_client = aws_helper.get_client(service='s3')
    keys = []
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=source_bucket, Prefix=source_prefix)
    for page in pages:
        for obj in page["Contents"]:
            keys.append(obj["Key"])
    for key in keys:
        metadata = get_metadatafor_key(
            key, s3_client, source_bucket
        )
        ciphertext = metadata["ciphertext"]
        datakeyencryptionkeyid = metadata["datakeyencryptionkeyid"]
        iv = metadata["iv"]
        plain_text_key = get_plaintext_key_calling_dks(
            ciphertext, datakeyencryptionkeyid
        )
        streaming_data = s3_client.get_object(Bucket=source_bucket, Key=key)['Body']
        decrypted_stream = decrypt(plain_text_key, iv, streaming_data)
        compress(decrypted_stream)
        credentials_dict = assume_role()
        boto3_session = boto3.session.Session(
        aws_access_key_id=credentials_dict["AccessKeyId"],
        aws_secret_access_key=credentials_dict["SecretAccessKey"],
        aws_session_token=credentials_dict["SessionToken"])
        save(s3_client, '', destination_bucket, destination_prefix)


def save(s3_client, file_name, destination_bucket, destination_prefix):
    with open(file_name, "rb") as data:
        s3_client.upload_fileobj(
            data,
            destination_bucket,
            # f"{destination_prefix}/{file_name}.enc",
            ExtraArgs={"Metadata": ''}
        )


def get_plaintext_key_calling_dks(
        encryptedkey, keyencryptionkeyid
):
    keys_map = []
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
        print("something")
        # the_logger.error(
        #     "Problem calling DKS for correlation id: %s and run id: %s %s",
        #     args.correlation_id,
        #     run_id,
        #     str(ex),
        # )
        # log_end_of_batch(args.correlation_id, run_id, FAILED_STATUS)
        # sys.exit(-1)
    return content["plaintextDataKey"]

def decrypt(plain_text_key, iv_key, data):
    try:
        iv_int = int(base64.b64decode(iv_key).hex(), 16)
        ctr = Counter.new(AES.block_size * 8, initial_value=iv_int)
        aes = AES.new(base64.b64decode(plain_text_key), AES.MODE_CTR, counter=ctr)
        decrypted = aes.decrypt(data)
    except BaseException as ex:
        print("something")
        # the_logger.error(
        #     "Problem decrypting data for correlation id and run id: %s %s %s",
        #     args.correlation_id,
        #     run_id,
        #     str(ex),
        # )
        # log_end_of_batch(args.correlation_id, run_id, FAILED_STATUS)
        # sys.exit(-1)
    return decrypted


def get_metadatafor_key(key, s3_client, source_bucket):
    s3_object = s3_client.get_object(Bucket=source_bucket, Key=key)
    iv = s3_object["Metadata"]["iv"]
    ciphertext = s3_object["Metadata"]["ciphertext"]
    datakeyencryptionkeyid = s3_object["Metadata"]["datakeyencryptionkeyid"]
    metadata = {
        "iv": iv,
        "ciphertext": ciphertext,
        "datakeyencryptionkeyid": datakeyencryptionkeyid,
    }
    return metadata


def decrypt(plain_text_key, iv_key, data, args, run_id):
    try:
        iv_int = int(base64.b64decode(iv_key).hex(), 16)
        ctr = Counter.new(AES.block_size * 8, initial_value=iv_int)
        aes = AES.new(base64.b64decode(plain_text_key), AES.MODE_CTR, counter=ctr)
        decrypted = aes.decrypt(data)
    except BaseException as ex:
        the_logger.error(
            "Problem decrypting data for correlation id and run id: %s %s %s",
            args.correlation_id,
            run_id,
            str(ex),
        )
        log_end_of_batch(args.correlation_id, run_id, FAILED_STATUS)
        sys.exit(-1)
    return decrypted


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

if __name__ == "__main__":
    try:
        receive_message_from_sqs()
    except Exception as e:
        print("something")



