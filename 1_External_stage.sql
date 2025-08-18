CREATE OR REPLACE STORAGE INTEGRATION azure_pacificretail_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = 'acf5eb60-d6be-4f92-adc5-f6b49d9f14b4'
  STORAGE_ALLOWED_LOCATIONS = ('azure://pacificretailprj.blob.core.windows.net/landing/');

  DESC STORAGE INTEGRATION azure_pacificretail_integration;
  
  

  CREATE OR REPLACE STAGE adls_stage
  STORAGE_INTEGRATION = azure_pacificretail_integration
  URL = 'azure://pacificretailprj.blob.core.windows.net/landing'