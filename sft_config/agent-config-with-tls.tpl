httpClient:
  timeout: 3600000ms
  connectionTimeout: 20000ms
  connectionRequestTimeout: 20000ms
  tls:
    verifyHostname: false
    keyStorePath: KEY_STORE_PATH
    keyStorePassword: KEYSTORE_PASSWORD
    trustStorePath: TRUST_STORE_PATH
    trustStorePassword: TRUST_STORE_PASSWORD
    supportedProtocols: [TLSv1.2]
    supportedCiphers: [TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
      TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
      TLS_DHE_DSS_WITH_AES_256_GCM_SHA384,
      TLS_DHE_DSS_WITH_AES_128_GCM_SHA256,
      TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,
      TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,
      TLS_RSA_WITH_AES_256_GCM_SHA384,
      TLS_RSA_WITH_AES_128_GCM_SHA256]
logging:
  appenders:
    - type: console
      threshold: INFO
      target: stdout
      logFormat: "%d{yyyy-MM-dd HH:mm:ss.SSS} [%30.30t] %-30.30c{1} %mdc{} %-5p %m%n"
    - type: file
      threshold: INFO
      logFormat: "%d{yyyy-MM-dd HH:mm:ss.SSS} [%30.30t] %-30.30c{1} %mdc{} %-5p %m%n"
      currentLogFilename: /var/log/sft/sft-agent.log
      archivedLogFilenamePattern: /var/log/sft-agent-%d.log.gz
      archivedFileCount: 7
      timeZone: UTC
apikey: ${apiKey}
<#include "agent-application-config.yml">
