sender: 
  retryBehaviour: 
    backOffMultiplier: 2
    maximumRedeliveries: 3
    maximumRedeliveryDelay: 3600000
    redeliveryDelay: 600000
  routes:
    - name: DA/Dataworks_UCFS_data
      source: /data-egress/warehouse/
      actions:
        - name: renameFile
           properties:
              rename_regex: (.+)
              rename_replacement: AWS_$1
        - name: httpRequest
          properties:
            destination: https://${destination_url}:8091/DA/Dataworks_UCFS_data
      errorFolder: /data-egress/error/warehouse
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DA/Dataworks_UCFS_tactical
      source: /data-egress/sas/
      actions:
        - name: renameFile
           properties:
              rename_regex: (.+)
              rename_replacement: AWS_$1
        - name: httpRequest
          properties:
            destination: https://${destination_url}:8091/DA/Dataworks_UCFS_tactical
      errorFolder: /data-egress/error/sas
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: DSP/Dataworks_UCFS_data
      source: /data-egress/RIS/
      actions:
        - name: renameFile
           properties:
              rename_regex: (.+)
              rename_replacement: AWS_$1
        - name: httpRequest
          properties:
            destination: https://${destination_url}:8091/DSP/Dataworks_UCFS_data
      errorFolder: /data-egress/error/RIS
      threadPoolSize: 5
      maxThreadPoolSize: 5
      deleteOnSend: true
      filenameRegex: .*
    - name: IFTS/testroute
      source: /data-egress/IFTS_Test
      actions:
        - name: renameFile
          properties:
            rename_regex: (.+)
            rename_replacement: AWS_$1
        - name: httpRequest
          properties:
            destination: https://${destination_url}:8091/IFTS/testroute
      deleteOnSend: true
      errorFolder: /data-egress/error/IFTS_Test
      filenameRegex: .*