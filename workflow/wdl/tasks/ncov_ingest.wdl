version 1.0

task gisaid_ingest {
  input {
    # based off of https://github.com/nextstrain/ncov-ingest#required-environment-variables
    String GISAID_API_ENDPOINT=""
    String GISAID_USERNAME_AND_PASSWORD=""
    String? AWS_DEFAULT_REGION
    String? AWS_ACCESS_KEY_ID
    String? AWS_SECRET_ACCESS_KEY
    #String? SLACK_TOKEN
    #String? SLACK_CHANNEL

    # Optional cached files
    File? cache_nextclade_old

    String giturl = "https://github.com/nextstrain/ncov-ingest/archive/refs/heads/modularize_upload.zip"
    #https://github.com/nextstrain/ncov-ingest/archive/refs/heads/master.zip"

    String docker_img = "nextstrain/ncov-ingest:latest"
    Int cpu = 16
    Int disk_size = 1500  # In GiB
    Float memory = 50     # In GiB
  }

  command <<<
    # Set up env variables
    export GISAID_API_ENDPOINT=~{GISAID_API_ENDPOINT}
    export GISAID_USERNAME_AND_PASSWORD=~{GISAID_USERNAME_AND_PASSWORD}

    export AWS_DEFAULT_REGION="~{AWS_DEFAULT_REGION}"
    export AWS_ACCESS_KEY_ID="~{AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="~{AWS_SECRET_ACCESS_KEY}"

    PROC=`nproc`
    temp_mem="~{memory}"
    MEM=${temp_mem%.*}000

    # Pull ncov-ingest repo
    wget -O master.zip ~{giturl}
    NCOV_INGEST_DIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
    unzip master.zip

    # Link cache files, instead of pulling from s3
    if [ -n "~{cache_nextclade_old}" ]
    then
      export NEXTCLADE_CACHE="~{cache_nextclade_old}"

      # Detect and uncompress xz files
      if [[ $NEXTCLADE_CACHE == *.xz ]];
      then
        xz --decompress ~{cache_nextclade_old}
        export NEXTCLADE_CACHE=`echo ~{cache_nextclade_old} | sed 's/.xz$//g'`
      fi

      mv $NEXTCLADE_CACHE ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv
    fi

    
    # Navigate to ncov-ingest directory, and call snakemake
    cd ${NCOV_INGEST_DIR}

    # Native run of snakemake?
    nextstrain build \
      --native \
      --cpus $PROC \
      --memory ~{memory}GiB \
      --exec env \
      . \
        snakemake \
          --configfile config/local_gisaid.yaml \
          --cores ${PROC} \
          --resources mem_mb=${MEM} \
          --printshellcmds

    # === prepare output
    # Date stamp the output files (YYYY-MM-DD)
    PREFIX=`date +%F` 

    cd ..
    # mv ${NCOV_INGEST_DIR}/log .
    # zip log
    ls -l ${NCOV_INGEST_DIR}/data/*
    mv ${NCOV_INGEST_DIR}/data/gisaid/sequences.fasta gisaid_sequences.fasta
    mv ${NCOV_INGEST_DIR}/data/gisaid/metadata.tsv gisaid_metadata.tsv
    xz --compress gisaid_sequences.fasta
    xz --compress gisaid_metadata.tsv

    # prepare output caches
    mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv ${PREFIX}_gisaid_nextclade.tsv
    if [ -f "${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv" ]
    then
      mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv ${PREFIX}_gisaid_nextclade.tsv
    fi
    xz --compress ${PREFIX}_gisaid_nextclade.tsv
  >>>

  output {
    # Ingested gisaid sequence and metadata files
    File sequences_fasta = "gisaid_sequences.fasta.xz"
    File metadata_tsv = "gisaid_metadata.tsv.xz"

    # cache for next run
    File nextclade_cache = "*_gisaid_nextclade.tsv.xz"
  }
  
  runtime {
    docker: docker_img
    cpu : cpu
    memory: memory + " GiB"
    disks: "local-disk " + disk_size + " HDD"
  }
}

task genbank_ingest {
  input {
    # Optional cached files
    File? cache_nextclade_old

    String giturl = "https://github.com/nextstrain/ncov-ingest/archive/refs/heads/modularize_upload.zip"
    #https://github.com/nextstrain/ncov-ingest/archive/refs/heads/master.zip"

    String docker_img = "nextstrain/ncov-ingest:latest"
    Int cpu = 16
    Int disk_size = 1500  # In GiB
    Float memory = 50
  }

  command <<<
    # Set up env variables
    PROC=`nproc`
    MEM=`echo $((("~{memory}"-3)*1000)) | sed 's/\.*//g'`

    # Pull ncov-ingest repo
    wget -O master.zip ~{giturl}
    NCOV_INGEST_DIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
    unzip master.zip

    # Link cache files, instead of pulling from s3
    if [ -n "~{cache_nextclade_old}" ]
    then
      export NEXTCLADE_CACHE="~{cache_nextclade_old}"

      # Detect and uncompress xz files
      if [[ $NEXTCLADE_CACHE == *.xz ]];
      then
        xz --decompress ~{cache_nextclade_old}
        export NEXTCLADE_CACHE=`echo ~{cache_nextclade_old} | sed 's/.xz$//g'`
      fi

      mv $NEXTCLADE_CACHE ${NCOV_INGEST_DIR}/data/genbank/nextclade_old.tsv
    fi

    
    # Navigate to ncov-ingest directory, and call snakemake
    cd ${NCOV_INGEST_DIR}

    # Native run of snakemake?
    nextstrain build \
      --native \
      --cpus $PROC \
      --memory ~{memory}GiB \
      --exec env \
      . \
        snakemake \
          --configfile config/local_genbank.yaml \
          --cores ${PROC} \
          --resources mem_mb=$MEM \
          --printshellcmds

    # === prepare output
    # Date stamp the output files (YYYY-MM-DD)
    PREFIX=`date +%F` 

    cd ..
    # mv ${NCOV_INGEST_DIR}/log .
    # zip log
    ls -l ${NCOV_INGEST_DIR}/data/*
    mv ${NCOV_INGEST_DIR}/data/genbank/sequences.fasta genbank_sequences.fasta
    mv ${NCOV_INGEST_DIR}/data/genbank/metadata.tsv genbank_metadata.tsv
    xz --compress genbank_sequences.fasta
    xz --compress genbank_metadata.tsv

    # prepare output caches
    mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv ${PREFIX}_genbank_nextclade.tsv
    if [ -f "${NCOV_INGEST_DIR}/data/genbank/nextclade.tsv" ]
    then
      mv ${NCOV_INGEST_DIR}/data/genbank/nextclade.tsv ${PREFIX}_genbank_nextclade.tsv
    fi
    xz --compress ${PREFIX}_genbank_nextclade.tsv
  >>>

  output {
    # Ingested gisaid sequence and metadata files
    File sequences_fasta = "genbank_sequences.fasta.xz"
    File metadata_tsv = "genbank_metadata.tsv.xz"

    # cache for next run
    File nextclade_cache = "*_genbank_nextclade.tsv.xz"
  }
  
  runtime {
    docker: docker_img
    cpu : cpu
    memory: memory + " GiB"
    disks: "local-disk " + disk_size + " HDD"
  }
}

