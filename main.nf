#!/usr/bin/env nextflow

include { seqQC; mafftAlign; alnQC } from './modules/SequenceQC.nf'
include { maskAln; iqtree; treePrune } from './modules/MaskingAndTreeQC.nf'

workflow seq_qc {
    main:
    // Define the input channels
    inFasta_ch = Channel.fromPath("${params.fasta}")
    inMetadata_ch = Channel.fromPath("${params.metadata}")
    inMinLen_ch = Channel.value("${params.min_length}")
    inMaxN_ch = Channel.value("${params.max_n_content}")
    // Call the functions
    seqQC_output = seqQC(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
    mafftAlign_output = mafftAlign(seqQC_output)
    alnQC(mafftAlign_output)
    
    emit:
    aln_tuple = mafftAlign.out.aln
    mask_tuple = alnQC.out.mask
}



workflow mask_and_tree_qc {
    // Define the input channels
    take:
    aln_in
    mask_in

    main:
    maskAln_output = maskAln(aln_in,mask_in)
    iqtree_output = iqtree(maskAln_output)
    treePrune(iqtree_output)

}

workflow {
    seq_qc()
    mask_and_tree_qc(seq_qc.out.aln_tuple,seq_qc.out.mask_tuple)
}