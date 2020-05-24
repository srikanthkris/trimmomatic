
Channel.fromFilePairs("./*_{R1,R2}.fastq")
        .into { ch_in_trimmomatic }


/*
###############
Trimmomatic
###############
*/

process trimmomatic {
    publishDir 'results/trimmomatic'
    container 'quay.io/biocontainers/trimmomatic:0.35--6'


    input:
    tuple genomeName, path(fq_1), path(fq_2) from ch_in_trimmomatic

    output:
    tuple  path(fq_1_paired), path(fq_1_unpaired), path(fq_2_paired), path(fq_2_unpaired) into ch_out_trimmomatic

    script:

    fq_1_paired = genomeName + '_R1.p.fastq'
    fq_1_unpaired = genomeName + '_R1.s.fastq'
    fq_2_paired = genomeName + '_R2.p.fastq'
    fq_2_unpaired = genomeName + '_R2.s.fastq'

    """
    trimmomatic \
    PE -phred33 \
    $fq_1 \
    $fq_2 \
    $fq_1_paired \
    $fq_1_unpaired \
    $fq_2_paired \
    $fq_2_unpaired \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:36
    """
}
