#!/usr/bin/env nextflow

/*
#==============================================
code documentation
#==============================================
*/


/*
#==============================================
params
#==============================================
*/

params.saveBy = 'copy'


Channel.fromFilePairs("./*_{R1,R2}.fastq")
        .into { ch_in_trimmomatic }


/*
#==============================================
trimmomatic
#==============================================
*/

process trimmomatic {
    publishDir 'results/trimmomatic', mode: params.saveBy
    container 'quay.io/biocontainers/trimmomatic:0.35--6'

    input:
    tuple genomeName, file(genomeReads) from ch_in_trimmomatic

    output:
    tuple path(fq_1_paired), path(fq_2_paired) into ch_out_trimmomatic

    script:

    fq_1_paired = genomeName + '_R1.p.fastq'
    fq_1_unpaired = genomeName + '_R1.s.fastq'
    fq_2_paired = genomeName + '_R2.p.fastq'
    fq_2_unpaired = genomeName + '_R2.s.fastq'

    """
    trimmomatic \
    PE -phred33 \
    ${genomeReads[0]} \
    ${genomeReads[1]} \
    $fq_1_paired \
    $fq_1_unpaired \
    $fq_2_paired \
    $fq_2_unpaired \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36
    """
}


/*
#==============================================
# extra
#==============================================
*/
