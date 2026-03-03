process seqQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_fasta.baseName}/seq-qc/", mode: "copy"
    
    debug true

    input:
    tuple val(sample_name), path(input_fasta)
    path input_metadata
    val min_length
    val max_n

    output:
    tuple val(sample_name), path("*.seq_qc.fasta"), emit: seq_qc_fasta
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    if (input_metadata.name != 'NO_FILE') {
        extra += " --metadata ${input_metadata}"
    }
    if (params.metadata_delimiter) {
        extra += " --metadata-delimiter '${params.metadata_delimiter}'"
    }
    if (params.metadata_id_field) {
        extra += " --metadata-id-field ${params.metadata_id_field}"
    }
    if (params.metadata_location_field) {
        extra += " --metadata-location-field ${params.metadata_location_field}"
    }
    if (params.metadata_date_field) {
        extra += " --metadata-date-field ${params.metadata_date_field}"
    }
    if (params.header_separator) {
        extra += " --header-separator '${params.header_separator}'"
    }
    if (params.id_delimiter) {
        extra += " --id_delimiter '${params.id_delimiter}'"
    }
    if (params.id_field) {
        extra += " --id-field ${params.id_field}"
    }

    """
    echo -e "\nFound the following fasta file(s): ${input_fasta}\n\nFound the following metadata file(s): ${input_metadata}"
    raccoon seq-qc ${input_fasta} -o ${sample_name}.seq_qc.fasta --min-length ${min_length} --max-n-content ${max_n} ${extra}
    """
}

process mafftAlign {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/mafft/", pattern: "*.aln.fasta", mode: "copy"

    input:
    tuple val(input_ID), path(qc_fasta)

    output:
    tuple val(input_ID), path("*.aln.fasta"), emit: aln

    script:
    """
    mafft ${qc_fasta} > ${input_ID}.aln.fasta
    """
}

process alnQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/aln-qc/", mode: "copy"
    
    input:
    tuple val(input_ID), path(aln_fasta)
    
    output:
    tuple val(input_ID), path("mask_sites.csv"), emit: mask
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    if (params.cluster_window) {
        extra += " --cluster-window ${params.cluster_window}"
    }
    if (params.cluster_count) {
        extra += " --cluster-count ${params.cluster_count}"
    }
    if (params.mask_clustered == true) {
        extra += " --mask-clustered"
    } else if (params.mask_clustered == false) {
        extra += " --no-mask-clustered"
    }
    if (params.mask_n_adjacent == true) {
        extra += " --mask-n-adjacent"
    } else if (params.mask_n_adjacent == false) {
        extra += " --no-mask-n-adjacent"
    }
    if (params.mask_gap_adjacent == true) {
        extra += " --mask-gap-adjacent"
    } else if (params.mask_gap_adjacent == false) {
        extra += " --no-mask-gap-adjacent"
    }
    if (params.mask_frame_break == true) {
        extra += " --mask-frame-break"
    } else if (params.mask_frame_break == false) {
        extra += " --no-mask-frame-break"
    }
    
    """
    raccoon aln-qc ${aln_fasta} ${extra}
    """
}