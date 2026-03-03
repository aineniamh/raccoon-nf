#!/usr/bin/env nextflow

include { seqQC; mafftAlign; alnQC } from './modules/SequenceQC.nf'
include { maskAln; iqtree; treePrune; treeQC } from './modules/MaskingAndTreeQC.nf'

workflow seq_qc {
    // Define the input channels
    take:
    inFasta_ch
    inMetadata_ch
    inMinLen_ch
    inMaxN_ch

    // Call the functions
    main:
    seqQC(inFasta_ch, inMetadata_ch, inMinLen_ch, inMaxN_ch)
    mafftAlign(seqQC.out.seq_qc_fasta)
    alnQC(mafftAlign.out.aln)
    
    emit:
    aln_tuple = mafftAlign.out.aln
    mask_tuple = alnQC.out.mask
}

workflow mask_aln {
    // Define the input channels
    take:
    aln_in
    mask_in

    main:
    maskAln(aln_in, mask_in)

    emit:
    maskAln_tuple = maskAln.out.masked_aln

}

workflow tree_qc {
    // Define the input channels
    take:
    aln_in

    main:
    iqtree(aln_in)
    treePrune(iqtree.out.treefile)
    treeQC(treePrune.out.pruned_tree, aln_in, iqtree.out.asr_file)


}

workflow {
    
    inMetadata_ch = Channel.fromPath("${params.metadata}")
    inMinLen_ch = Channel.value("${params.min_length}")
    inMaxN_ch = Channel.value("${params.max_n_content}")

    // check inFasta_ch is a directory or a file.
    input_fasta = file("${params.fasta}")
    if ( input_fasta.extension.equals("fasta") || input_fasta.extension.equals("fa")) {
        inFasta_ch = Channel.fromPath(input_fasta).map { [it.baseName, it] }
    } else {
        input_dir_files = file("${params.fasta}").list()
        fasta_extensions = [".fasta", ".fa"]
	    matching_files =  input_dir_files.findAll { a -> fasta_extensions.any { a.contains(it) } }
        input_files = matching_files.collect {"$input_fasta/$it"}
        inFasta_ch = Channel.fromPath(input_files).collect().map { [input_fasta.baseName, it] }
    }

    // conditional statement here to stop after alignment
    if (params.alignment_only == true) {
        seq_qc(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
    } else {
        seq_qc(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
        // conditional statement here to choose to use the generated mask or not
        if (params.skip_mask == false) {
            mask_aln(seq_qc.out.aln_tuple, seq_qc.out.mask_tuple)
            tree_qc(mask_aln.out.maskAln_tuple)
        } else if (params.skip_mask == true) {
            tree_qc(seq_qc.out.aln_tuple)
        }
    }
}