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
            destination: "https://${destination_url}:8091/IFTS/testroute"
      deleteOnSend: true
      errorFolder: /data-egress/error/IFTS_Test
      filenameRegex: .*
      name: IFTS/testroute
      source: /data-egress/IFTS_Test
