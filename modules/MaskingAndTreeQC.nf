"""
# 2. Masking and tree QC
raccoon mask examples/mev/aln-qc/mev_sample.aln.fasta --mask-file examples/mev/aln-qc/mask_sites.csv -d examples/mev/masked/
# realign if sequence removed?

iqtree -s examples/mev/masked/mev_sample.aln.masked.fasta -m HKY -czb -blmin 0.00000001 -asr -o 'PP_003MAAS.2||2019'

jclusterfunk prune -i "examples/mev/masked/mev_sample.aln.masked.fasta.treefile" -t 'PP_003MAAS.2||2019' -o 'examples/mev/masked/mev_sample.pruned.tree'

raccoon tree-qc --phylogeny 'examples/mev/masked/mev_sample.pruned.tree' --asr-state examples/mev/masked/mev_sample.aln.masked.fasta.state --alignment examples/mev/masked/mev_sample.aln.masked.fasta -d examples/mev/tree-qc/
"""

process maskAln {
    conda "${HOME}/miniconda3/envs/raccoon"
    publishDir "results/${input_ID}/mask_alignment/"

    input:
    tuple val(input_ID), path(aln_file)
    tuple val(input_ID), path(mask_file)

    output:
    tuple val(input_ID), path("*.aln.masked.fasta")

    script:
    """
    raccoon mask ${aln_file} --mask-file ${mask_file}
    """
}

process iqtree {
    conda "${HOME}/miniconda3/envs/raccoon"
    publishDir "results/${input_ID}/tree/"

    input:
    tuple val(input_ID), path(aln_file)

    output:
    tuple val(input_ID), path("*.treefile")

    script:
    """
    iqtree -s ${aln_file} -m HKY -czb -blmin 0.00000001 -asr -o 'PP_003MAAS.2||2019'
    """
}

process treePrune {
    conda "${HOME}/miniconda3/envs/raccoon"
    publishDir "results/${input_ID}/pruned_tree/"

    input:
    tuple val(input_ID), path(treefile)

    output:
    tuple val(input_ID), path("*.pruned.tree")

    script:
    """
    jclusterfunk prune -i "${treefile}" -t 'PP_003MAAS.2||2019' -o '${input_ID}.pruned.tree'
    """
}

process treeQC {
    conda "${HOME}/miniconda3/envs/raccoon"
    publishDir "results/${input_ID}/tree-qc/"

    input:
    tuple val(input_ID), path(pruned_treefile)

    output:
    tuple val(input_ID), path("*.pruned.tree")

    script:
    """
    raccoon tree-qc --phylogeny '${pruned_treefile}' --asr-state examples/mev/masked/mev_sample.aln.masked.fasta.state --alignment examples/mev/masked/mev_sample.aln.masked.fasta -d examples/mev/tree-qc/
    """
}
