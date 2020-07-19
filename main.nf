#!/usr/bin/env nextflow

/*
################
params
################
*/


params.saveBy= 'copy'
params.compressedInput= true
params.deleteOriginal= false
params.resultsDir= 'results/trimmomatic'



compressedInputFilePattern = "./*_{R1,R2}.fastq.gz"
decompressedInputFilePattern = "./*_{R1,R2}.fastq"

inputFilePattern = params.compressedInput ? compressedInputFilePattern : decompressedInputFilePattern


/*
################
gunzip these files
################
*/


if(params.compressedInput) {

Channel.fromFilePairs(inputFilePattern)
        .into { ch_in_gzip }


process gzip {
    container 'abhi18av/biodragao_base'

    input:
    set genomeName, file(genomeReads) from ch_in_gzip

    output:
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) into ch_in_trimmomatic

    script:
    outputExtension = '.fastq'
    
    // rename the output files
    genome_1_fq = genomeReads[0].name.split("\\.")[0] + outputExtension
    genome_2_fq = genomeReads[1].name.split("\\.")[0] + outputExtension

    """
    gzip -dc ${genomeReads[0]} > ${genome_1_fq} 
    gzip -dc ${genomeReads[1]} > ${genome_2_fq}
    """

    }
        
} else {


Channel.fromFilePairs(inputFilePattern, flat: true)
        .into { ch_in_trimmomatic }

}

/*
###############
Trimmomatic
###############
*/

process trimmomatic {
    publishDir params.resultsDir, mode: params.saveBy
    container 'quay.io/biocontainers/trimmomatic:0.35--6'

    input:
    tuple genomeName, path(genome_1_fq), path(genome_2_fq) from ch_in_trimmomatic

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
    
    gzip ${fq_1_paired}  
    gzip ${fq_2_paired} 
    
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



