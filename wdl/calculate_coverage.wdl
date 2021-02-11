version 1.0

import "Structs.wdl"

workflow countCoverage {

  #################################################################################
  ####        Required basic arguments                                            #
  #################################################################################
    
  input {
    File reference_fasta
    String downsample_docker
    File cram_in

    File ref_amb
    File ref_ann
    File ref_bwt
    File ref_pac
    File ref_sa
    File ref_fai
    File ref_dict

    File? gatk4_jar_override

    # Runtime configuration overrides
    RuntimeAttr? runtime_attr_combine_random_sort
    RuntimeAttr? runtime_attr_realign
    RuntimeAttr? runtime_attr_add_read_group
    RuntimeAttr? runtime_attr_mark_duplicates
    RuntimeAttr? runtime_attr_sort_index
    RuntimeAttr? runtime_attr_count_coverage
    RuntimeAttr? runtime_attr_collect_counts
  }

  parameter_meta {
    cram_in: "cram file to get coverage metrics for"
    reference_fasta: ".fasta file with reference used to align bam or cram file"
  }

  meta {
    author: "Elise Valkanas"
    email: "valkanas@broadinstitute.org"
  }

  output {
    File wgsCoverage_metrics = countCoverage.wgs_coverage_file
  }
    

  call countCoverage {
    input : 
      input_cram = cram_in,
      reference_fasta = reference_fasta,
      downsample_docker = downsample_docker,
      runtime_attr_override = runtime_attr_count_coverage,
      reference_dict = ref_dict,
      ref_amb = ref_amb,
      ref_ann = ref_ann,
      ref_bwt = ref_bwt,
      ref_pac = ref_pac,
      ref_sa = ref_sa,
      ref_fai = ref_fai 
  }
}

task countCoverage {
    
  input {
    File input_cram
    File reference_fasta
    String downsample_docker
    File reference_dict
    File ref_amb
    File ref_ann
    File ref_bwt
    File ref_pac
    File ref_sa
    File ref_fai
    RuntimeAttr? runtime_attr_override
  }

  Int num_cpu = 1
  Int mem_size_gb = 4
  Int vm_disk_size = 50

  RuntimeAttr default_attr = object {
    cpu_cores: num_cpu,
    mem_gb: mem_size_gb, 
    disk_gb: vm_disk_size,
    boot_disk_gb: 10,
    preemptible_tries: 3,
    max_retries: 1
  }

  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  String wgs_coverage_name = basename(input_cram, ".cram") + "_coverage.txt"
  String ref_dictionary_name = "Homo_sapiens_assembly38.dict"

  output {
    File wgs_coverage_file = wgs_coverage_name
  }

  command <<<
    set -euo pipefail

    java -Xmx4G -jar /opt/conda/share/picard-2.23.8-0/picard.jar CollectWgsMetrics \
      I=~{input_cram} \
      O=~{wgs_coverage_name} \
      R=~{reference_fasta} \
      COUNT_UNPAIRED=TRUE
    >>>

  runtime {
    docker: downsample_docker
    cpu: select_first([runtime_attr.cpu_cores, default_attr.cpu_cores])
    memory: select_first([runtime_attr.mem_gb, default_attr.mem_gb]) + " GiB"
    disks: "local-disk " + select_first([runtime_attr.disk_gb, default_attr.disk_gb]) + " HDD"
    bootDiskSizeGb: select_first([runtime_attr.boot_disk_gb, default_attr.boot_disk_gb])
    preemptible: select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
    maxRetries: select_first([runtime_attr.max_retries, default_attr.max_retries])
  }
}



