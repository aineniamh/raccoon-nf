#!/usr/bin/env nextflow

include { seqQC; mafftAlign; alnQC } from './modules/SequenceQC.nf'

workflow seq_qc {
    // Define the input channels
    inFasta_ch = Channel.fromPath("${params.fasta}")
    inMetadata_ch = Channel.fromPath("${params.metadata}")
    inMinLen_ch = Channel.value("${params.min_length}")
    inMaxN_ch = Channel.value("${params.max_n_content}")
    // Call the functions
    seqQC_output = seqQC(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
    mafftAlign_output = mafftAlign(seqQC_output)
    alnQC(mafftAlign_output)
}

workflow {
    seq_qc()
}