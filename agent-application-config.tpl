sender:
  routes:
    - name: DA/Dataworks_UCFS_data
      source: /data-egress/warehouse/
      actions:
        - name: httpRequest
          properties:
            destination: ${destination_url}
      errorFolder: /data-egress/error/warehouse
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DA/Dataworks_UCFS_tactical
      source: /data-egress/sas/
      actions:
        - name: httpRequest
          properties:
            destination: ${destination_url}
      errorFolder: /data-egress/error/sas
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DSP/Dataworks_UCFS_data
      source: /data-egress/RIS/
      actions:
        - name: httpRequest
          properties:
            destination: ${destination_url}
      errorFolder: /data-egress/error/RIS
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
  retryBehaviour:
    maximumRedeliveries: 3
    redeliveryDelay: 600000
    maximumRedeliveryDelay: 3600000
    backOffMultiplier: 2

