#!/bin/bash

# Force LC update when any of these files are changed
echo "${s3_file_data_egress_server_logrotate_md5}" > /dev/null
echo "${s3_file_data_egress_server_cloudwatch_sh_md5}" > /dev/null

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d'"' -f4)

/etc/init.d/awsagent stop
sleep 5
/etc/init.d/awsagent start

echo "Configuring startup scripts paths"
S3_URI_LOGROTATE="s3://${s3_scripts_bucket}/${s3_file_data_egress_server_logrotate}"
S3_CLOUDWATCH_SHELL="s3://${s3_scripts_bucket}/${s3_file_data_egress_server_cloudwatch_sh}"

echo "Configuring startup file paths"
mkdir -p /opt/data_egress_server/

echo "Installing startup scripts"
aws s3 cp "$S3_URI_LOGROTATE"          /etc/logrotate.d/data_egress_server
aws s3 cp "$S3_CLOUDWATCH_SHELL"       /opt/data_egress_server/data_egress_server_cloudwatch.sh

echo "Allow shutting down"
echo "data_egress_server     ALL = NOPASSWD: /sbin/shutdown -h now" >> /etc/sudoers

echo "Creating directories"
mkdir -p /var/log/data_egress_server

echo "Setup cloudwatch logs"
chmod u+x /opt/data_egress_server/data_egress_server_cloudwatch.sh
/opt/data_egress_server/data_egress_server_cloudwatch.sh \
"${cwa_metrics_collection_interval}" "${cwa_namespace}" "${cwa_cpu_metrics_collection_interval}" \
"${cwa_disk_measurement_metrics_collection_interval}" "${cwa_disk_io_metrics_collection_interval}" \
"${cwa_mem_metrics_collection_interval}" "${cwa_netstat_metrics_collection_interval}" "${cwa_log_group_name}" \
"$AWS_DEFAULT_REGION"

echo "${environment_name}" > /opt/data_egress_server/environment
export HTTP_PROXY="http://${internet_proxy}:3128"
export HTTPS_PROXY="$HTTP_PROXY"
export NO_PROXY="${non_proxied_endpoints},${dks_fqdn}"

echo "Configure AWS Inspector"
cat > /etc/init.d/awsagent.env << AWSAGENTPROXYCONFIG
export HTTPS_PROXY=$HTTPS_PROXY
export HTTP_PROXY=$HTTP_PROXY
export NO_PROXY=$NO_PROXY
AWSAGENTPROXYCONFIG

# Retrieve certificates
ACM_KEY_PASSWORD=$(uuidgen -r)
echo "Retrieving acm certs"
acm-cert-retriever \
--acm-cert-arn "${acm_cert_arn}" \
--acm-key-passphrase "$ACM_KEY_PASSWORD" \
--private-key-alias "${private_key_alias}" \
--truststore-aliases "${truststore_aliases}" \
--truststore-certs "${truststore_certs}" >> /var/log/acm-cert-retriever.log 2>&1

unset HTTPS_PROXY HTTP_PROXY NO_PROXY
