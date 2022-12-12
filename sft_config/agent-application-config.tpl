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

// AWS SFT Hub Routes 

    // - name: internal/DA/inbound/Dataworks_UCFS_data
    //   source: /data-egress/warehouse/
    //   actions:
    //     - name: renameFile
    //        properties:
    //           rename_regex: (.+)
    //           rename_replacement: AWS_$1
    //     - name: httpRequest
    //       properties:
    //         destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Dataworks_UCFS_data"
    //   errorFolder: /data-egress/error/warehouse
    //   threadPoolSize: 5
    //   maxThreadPoolSize: 5
    //   deleteOnSend: true
    //   filenameRegex: .*

    // - name: internal/DA/inbound/Dataworks_UCFS_Tactical
    //   source: /data-egress/sas
    //   actions:
    //      - name: renameFile
    //        properties:
    //           rename_regex: (.+)
    //           rename_replacement: AWS_$1
    //     - name: httpRequest
    //       properties:
    //         destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Dataworks_UCFS_Tactical"
    //   errorFolder: /data-egress/error/sas
    //   threadPoolSize: 5
    //   maxThreadPoolSize: 5
    //   deleteOnSend: true
    //   filenameRegex: .*

    // - name: internal/DSP/inbound/Dataworks_UCFS_data
    //   source: /data-egress/RIS/
    //   actions:
    //     - name: renameFile
    //        properties:
    //           rename_regex: (.+)
    //           rename_replacement: AWS_$1
    //     - name: httpRequest
    //       properties:
    //         destination: "https://${aws_destination_url}:8091/internal/DSP/inbound/Dataworks_UCFS_data"
    //   errorFolder: /data-egress/error/RIS
    //   threadPoolSize: 5
    //   maxThreadPoolSize: 5
    //   deleteOnSend: true
    //   filenameRegex: .*

    // - name: internal/GFTS/inbound/Test
    //   source: /data-egress/test
    //   actions:
    //     - name: renameFile
    //        properties:
    //           rename_regex: (.+)
    //           rename_replacement: AWS_$1
    //     - name: httpRequest
    //       properties:
    //         destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Test"
    //   errorFolder: /data-egress/error/test
    //   deleteOnSend: true
    //   filenameRegex: .*
