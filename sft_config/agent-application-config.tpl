sender:
  retryBehaviour:
    backOffMultiplier: 2
    maximumRedeliveries: 3
    maximumRedeliveryDelay: 3600000
    redeliveryDelay: 600000
  routes:

    - name: internal/CRE/inbound/Dataworks/UCFS/data-CopySubsetToBothRISandCRE
      source: /data-egress/RIS/
      actions:
        - name: writeFile
          properties:
            destination: /data-egress/ris-tmp/
        - name: writeFile
          properties:
            destination: /data-egress/cre-tmp/
      errorFolder: /data-egress/error/CRE
      deleteOnSend: true
      filenameRegex: ^db.(core.(statement$|claimant$|contract$)|accepted-data.(address$|childrenCircumstances$|personDetails$)|crypto.(encryptedData-unencrypted$).*)$

    - name: internal/CRE/inbound/Dataworks/UCFS/data-CopyOtherThanSubsetToRIS
      source: /data-egress/RIS/
      actions:
        - name: writeFile
          properties:
            destination: /data-egress/ris-tmp/
      errorFolder: /data-egress/error/RIS
      deleteOnSend: true
      filenameRegex:  ^db.((?!core.(statement$|claimant$|contract$)|accepted-data.(address$|childrenCircumstances$|personDetails$)|crypto.(encryptedData-unencrypted$)).*)$

    - name: internal/DSPRIS/inbound/Dataworks/UCFS/data
      source: /data-egress/ris-tmp/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DSPRIS/inbound/Dataworks/UCFS/data"
      errorFolder: /data-egress/error/RIS
      deleteOnSend: true
      filenameRegex: ^.*$
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DandARed/inbound/Dataworks/UCFS/tactical
      source: /data-egress/sas/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DandARed/inbound/Dataworks/UCFS/tactical"
      errorFolder: /data-egress/error/sas
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DandARed/inbound/Dataworks/UCFS/data
      source: /data-egress/warehouse/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DandARed/inbound/Dataworks/UCFS/data"
      errorFolder: /data-egress/error/warehouse
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: startupTest
      source: /data-egress/test/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/DA"
      errorFolder: /data-egress/error/test
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DandARed/inbound/Test
      source: /data-egress/awstest/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DandARed/inbound/Test"
      errorFolder: /data-egress/error/awstest
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DA/inbound/Test
      source: /data-egress/pptest/
      actions:
        - name: renameFile
          properties:
            rename_regex: (.+)
            rename_replacement: TEST_$1
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Test"
      errorFolder: /data-egress/error/pptest
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DA/inbound/SendTo-CRE
      source: /data-egress/cre-tmp/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/CEHA/inbound/Dataworks/UCFS/data"
      errorFolder: /data-egress/error/CRE
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3
