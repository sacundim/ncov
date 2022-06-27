**************************
Run GISAID Ingest on Terra
**************************

Import ``ingest`` wdl workflow from Dockstore
=============================================

1. `Setup a Terra account <https://terra.bio/>`_
#. Navigate to Dockstore: `ncov:wdl/temp_ingest`_
#. Top right corner, under **Launch with**, click on **Terra**
#. Under "Workflow Name" set a name, such as ``gisaid_ingest``, and select your "Destination Workspace" in the drop down menu.
#. Click button **IMPORT**
#. In your workspace, click on the **WORKFLOWS** tab and verify that the imported workflow is showing a card

.. _`ncov:wdl/temp_ingest`: https://dockstore.org/workflows/github.com/nextstrain/ncov:wdl/temp_ingest?tab=info

Create Terra Variables for GISAID API
=====================================

1. Navigate to your workspace on Terra
#. On the **Data** tab, from the left menu click **Workspace Data**
#. Create and fill in values for the following workspace variables:

  +-----------------------------+----------------------------+-----------------------------------------------+
  |Key                          | Value                      | Description                                   |
  +=============================+============================+===============================================+
  |GISAID_API_ENDPOINT          | url api enpoint value here | Provided by GISAID for your account           |
  +-----------------------------+----------------------------+-----------------------------------------------+
  |GISAID_USERNAME_AND_PASSWORD |  username:password         | Your GISAID username password for api access  |
  +-----------------------------+----------------------------+-----------------------------------------------+

Connect your workspace variables to the wdl ingest workflow
===========================================================
  
1. Navigate back to the **Workflow** tab, and click on your imported "gisaid_ingest" workflow
#. Click on the radio button "Run workflow(s) with inputs defined by data table"
#. Under **Step 1**, select your root entity type **ncov_examples** from the drop down menu. 
#. ONLY select the 1st entry in the data table. We only want to run this once.
#. Most of the values will be blank but fill in the values below: 

  +-----------------+-------------------------------+-------+----------------------------------------+
  |Task name        | Variable                      | Type  | Attribute                              |
  +=================+===============================+=======+========================================+
  |Nextstrain_WRKFLW|  GISAID_API_ENDPOINT          | String| workspace.GISAID_API_ENDPOINT          |
  +-----------------+-------------------------------+-------+----------------------------------------+
  |Nextstrain_WRKFLW|  GISAID_USERNAME_AND_PASSWORD | String| workspace.GISAID_USERNAME_AND_PASSWORD |
  +-----------------+-------------------------------+-------+----------------------------------------+

6. Click on the **OUTPUTS** tab
#. Connect your generated output back to the workspace data, but filling in values:

  +-----------------+------------------+-------+----------------------------------+
  |Task name        | Variable	       | Type  |   Attribute                      |
  +=================+==================+=======+==================================+
  |Nextstrain_WRKFLW|  sequences_fasta | File  | workspace.gisaid_sequences_fasta |
  +-----------------+------------------+-------+----------------------------------+
  |Nextstrain_WRKFLW|  metadata_tsv    | File  | workspace.gisaid_metadata_tsv    |
  +-----------------+------------------+-------+----------------------------------+
  |Nextstrain_WRKFLW|  nextclade_tsv   | File  | workspace.gisaid_nextclade_tsv   |
  +-----------------+------------------+-------+----------------------------------+


8. Click on **Save** then click on **Run Analysis**
#. Under the tab **JOB HISTORY**, verify that your job is running.
#. When run is complete, check the **DATA** / **Workspace Data** tab and use the "workspace.gisaid_sequences_fasta" and "workspace.gisaid_metadata.tsv" during normal ncov Terra runs.