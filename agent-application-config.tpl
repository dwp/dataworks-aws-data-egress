sender:
  routes:
    - name: DA/Dataworks_UCFS_data
      source: /data/warehouse/
      actions:
        - name: httpRequest
          properties:
            destination: https://${destinationIP}:8091/DA/Dataworks_UCFS_data
      errorFolder: /data/error/warehouse
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DA/Dataworks_UCFS_tactical
      source: /data/sas/
      actions:
        - name: httpRequest
          properties:
            destination: https://${destinationIP}:8091/DA/Dataworks_UCFS_tactical
      errorFolder: /data/error/sas
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DSP/Dataworks_UCFS_data
      source: /data/RIS/
      actions:
        - name: httpRequest
          properties:
            destination: https://${destinationIP}:8091/DSP/Dataworks_UCFS_data
      errorFolder: /data/error/RIS
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
  retryBehaviour:
    maximumRedeliveries: 3
    redeliveryDelay: 600000
    maximumRedeliveryDelay: 3600000
    backOffMultiplier: 2

