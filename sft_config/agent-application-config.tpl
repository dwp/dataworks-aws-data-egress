sender: 
  retryBehaviour: 
    backOffMultiplier: 2
    maximumRedeliveries: 3
    maximumRedeliveryDelay: 3600000
    redeliveryDelay: 600000
  routes: 
    - 
      actions:
        - 
          name: httpRequest
          properties: 
            destination: "https://${oph_destination_url}:8091/DA/Dataworks_UCFS_data"
      deleteOnSend: true
      errorFolder: /data-egress/error/warehouse
      filenameRegex: .*
      maxThreadPoolSize: 3
      name: DA/Dataworks_UCFS_data
      source: /data-egress/warehouse/
      threadPoolSize: 3
    - 
      actions:
        - 
          name: httpRequest
          properties: 
            destination: "https://${oph_destination_url}:8091/DA/Dataworks_UCFS_tactical"
      deleteOnSend: true
      errorFolder: /data-egress/error/sas
      filenameRegex: .*
      maxThreadPoolSize: 3
      name: DA/Dataworks_UCFS_tactical
      source: /data-egress/sas/
      threadPoolSize: 3
    - 
      actions:
        - 
          name: httpRequest
          properties: 
            destination: "https://${oph_destination_url}:8091/DSP/Dataworks_UCFS_data"
      deleteOnSend: true
      errorFolder: /data-egress/error/RIS
      filenameRegex: .*
      maxThreadPoolSize: 3
      name: DSP/Dataworks_UCFS_data
      source: /data-egress/RIS/
      threadPoolSize: 3
    - 
      actions:
        - 
          name: httpRequest
          properties: 
            destination: "https://${oph_destination_url}:8091/DA"
      deleteOnSend: true
      errorFolder: /data-egress/error/test
      filenameRegex: .*
      maxThreadPoolSize: 3
      name: startupTest
      source: /data-egress/test/
      threadPoolSize: 3

    - name: internal/GFTS/inbound/Test
      source: /data-egress/test
      actions:
        - name: renameFile
           properties:
              rename_regex: (.+)
              rename_replacement: AWS_$1
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Test"
      errorFolder: /data-egress/error/test
      deleteOnSend: true
      filenameRegex: .*
