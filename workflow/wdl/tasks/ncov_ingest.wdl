version 1.0

# Drafting thoughts here

task ncov_ingest {
  input {
    # based off of https://github.com/nextstrain/ncov-ingest#required-environment-variables
    String GISAID_API_ENDPOINT=""
    String GISAID_USERNAME_AND_PASSWORD=""
    String AWS_DEFAULT_REGION=""
    String AWS_ACCESS_KEY_ID=""
    String AWS_SECRET_ACCESS_KEY=""
    #String? SLACK_TOKEN
    #String? SLACK_CHANNEL

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
    export GISAID_API_ENDPOINT=~{GISAID_API_ENDPOINT}
    export GISAID_USERNAME_AND_PASSWORD=~{GISAID_USERNAME_AND_PASSWORD}
    export AWS_DEFAULT_REGION=~{AWS_DEFAULT_REGION}
    export AWS_ACCESS_KEY_ID=~{AWS_ACCESS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=~{AWS_SECRET_ACCESS_KEY}

    # Pull ncov-ingest repo
    wget -O master.zip ~{giturl}
    NCOV_INGEST_DIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
    unzip master.zip

#    # List available scripts
#    echo $NCOV_INGEST_DIR
#    ls $NCOV_INGEST_DIR/bin/*
#
#    touch ncov_ingest.zip

    # Link cache files, instead of pulling from s3
    if [ -n "~{cache_nextclade_old}" ]
    then
      mv ~{cache_nextclade_old} ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv
    fi

    PROC=`nproc` # Max out processors, although not sure if it matters here
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
          --resources mem_mb=47000 \
          --printshellcmds

    # === prepare output
    cd ..
    # mv ${NCOV_INGEST_DIR}/log .
    # zip log
    ls -l ${NCOV_INGEST_DIR}/data/*
    mv ${NCOV_INGEST_DIR}/data/gisaid/sequences.fasta .
    mv ${NCOV_INGEST_DIR}/data/gisaid/metadata.tsv .
    xz --compress sequences.fasta
    xz --compress metadata.tsv

    # prepare output caches
    mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv nextclade.tsv
    if [ -f "${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv" ]
    then
      mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv .
    fi
    xz --compress nextclade.tsv
  >>>

  output {
    # Ingested gisaid sequence and metadata files
    File sequences_fasta = "sequences.fasta.xz"
    File metadata_tsv = "metadata.tsv.xz"

    # cache for next run
    File nextclade_cache = "nextclade.tsv.xz" 
    #File aligned_cache = "aligned.fasta"
  }
  
  runtime {
    docker: docker_img
    cpu : cpu
    memory: memory + " GiB"
    disks: "local-disk " + disk_size + " HDD"
  }
}