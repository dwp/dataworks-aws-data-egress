sender:
  retryBehaviour:
    backOffMultiplier: 2
    maximumRedeliveries: 3
    maximumRedeliveryDelay: 3600000
    redeliveryDelay: 600000
  routes:

    - name: internal/DSPRIS/inbound/Dataworks/UCFS/data
      source: /data-egress/RIS/
      actions:
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DSPRIS/inbound/Dataworks/UCFS/data"
      errorFolder: /data-egress/error/RIS
      deleteOnSend: true
      filenameRegex: .*
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

    - name: internal/DA/inbound/TestCopy
      source: /data-egress/pptest/
      actions:
        - name: writeFile
          properties:
            destination: /data-egress/pptest-copy/
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Test"
      errorFolder: /data-egress/error/pptest
      deleteOnSend: true
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DA/inbound/TestSend
      source: /data-egress/pptest-copy/
      actions:
        - name: writeFile
          properties:
            destination: /data-egress/pptest-copy-dest/
        - name: httpRequest
          properties:
            destination: "https://${aws_destination_url}:8091/internal/DA/inbound/Test"
      errorFolder: /data-egress/error/pptest-copy-dest
      deleteOnSend: true
      filenameRegex: ^[a|b\\c]$
      maxThreadPoolSize: 3
      threadPoolSize: 3

    - name: internal/DA/inbound/TestCleanUp
      source: /data-egress/pptest-copy/
      actions:
        - name: runScript
          properties:
            script: rm -rf *
            waitForCompletion: true
      errorFolder: /data-egress/error/pptest-copy
      filenameRegex: .*
      maxThreadPoolSize: 3
      threadPoolSize: 3
