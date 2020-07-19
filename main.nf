#!/usr/bin/env nextflow

/*
################
params
################
*/


params.saveBy= 'copy'
params.compress= true
params.deleteOriginal= false
params.resultsDir= 'results/trimmomatic'


Channel.fromFilePairs("./*_{R1,R2}.fastq")
        .into { ch_in_trimmomatic }


/*
###############
Trimmomatic
###############
*/

process trimmomatic {
    publishDir params.resultsDir, mode: params.saveBy
    container 'quay.io/biocontainers/trimmomatic:0.35--6'

    input:
    tuple genomeName, file(genomeReads) from ch_in_trimmomatic

    output:
    tuple  path(fq_1_paired_gzip), path(fq_2_paired_gzip) into ch_out_trimmomatic
    file(genomeReads) into ch_in_trimmomatic_deleteOriginal

    script:

    fq_1_paired = genomeName + '_R1.p.fastq'
    fq_1_unpaired = genomeName + '_R1.s.fastq'
    fq_2_paired = genomeName + '_R2.p.fastq'
    fq_2_unpaired = genomeName + '_R2.s.fastq'
        
    // rename the output compressed files
    fq_1_paired_gzip = fq_1_paired + ".gz"
    fq_2_paired_gzip = fq_2_paired + ".gz"
    
    
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
    
    gzip ${fq_1_paired} > ${fq_1_paired_gzip} 
    gzip ${fq_2_paired} > ${fq_2_paired_gzip} 
    
    """
}


if(params.deleteOriginal) {

process trimmomatic_deleteOriginal {
    container 'quay.io/biocontainers/trimmomatic:0.35--6'
    
    echo true

    input: 
    file(genomeReads) from ch_in_trimmomatic_deleteOriginal
    
    script:
    
    """
    echo ${genomeReads[0]}
    echo ${genomeReads[1]}
    
    """
  }
}



