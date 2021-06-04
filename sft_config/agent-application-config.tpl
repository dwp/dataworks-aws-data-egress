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
          name: renameFile
          properties: 
            rename_regex: (.+)
            rename_replacement: AWS_$1
        - 
          name: httpRequest
          properties: 
            destination: "https://${destination_url}:8091/DA/Dataworks_UCFS_data"
      deleteOnSend: true
      errorFolder: /data-egress/error/warehouse
      filenameRegex: .*
      maxThreadPoolSize: 5
      name: DA/Dataworks_UCFS_data
      source: /data-egress/warehouse/
      threadPoolSize: 5
    - 
      actions: 
        - 
          name: renameFile
          properties: 
            rename_regex: (.+)
            rename_replacement: AWS_$1
        - 
          name: httpRequest
          properties: 
            destination: "https://${destination_url}:8091/DA/Dataworks_UCFS_tactical"
      deleteOnSend: true
      errorFolder: /data-egress/error/sas
      filenameRegex: .*
      maxThreadPoolSize: 5
      name: DA/Dataworks_UCFS_tactical
      source: /data-egress/sas/
      threadPoolSize: 5
    - 
      actions: 
        - 
          name: renameFile
          properties: 
            rename_regex: (.+)
            rename_replacement: AWS_$1
        - 
          name: httpRequest
          properties: 
            destination: "https://${destination_url}:8091/DSP/Dataworks_UCFS_data"
      deleteOnSend: true
      errorFolder: /data-egress/error/RIS
      filenameRegex: .*
      maxThreadPoolSize: 5
      name: DSP/Dataworks_UCFS_data
      source: /data-egress/RIS/
      threadPoolSize: 5
    - 
      actions: 
        - 
          name: renameFile
          properties: 
            rename_regex: (.+)
            rename_replacement: AWS_$1
        - 
          name: httpRequest
          properties: 
            destination: "https://${destination_url}:8091/DA"
      deleteOnSend: true
      errorFolder: /data-egress/error/data-egress-testing-output
      filenameRegex: .*
      maxThreadPoolSize: 5
      name: e2eTest
      source: /data-egress/data-egress-testing-output/
      threadPoolSize: 5
