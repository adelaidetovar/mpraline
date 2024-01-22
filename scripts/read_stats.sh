#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 cutadapt_dir umitools_dir deduplicated_dir clustered_barcodes_dir out_tab"
    exit 1
fi

cutadapt_dir=$1
umitools_dir=$2
deduplicated_dir=$3
clustered_barcodes_dir=$4
out_tab=$5

# Initialize summary table
echo -e "Sample\tInput_Read_Pairs\tPass_Cutadapt_Read_Pairs\tPass_Cutadapt_Percentage\tPass_Umitools_Read_Pairs\tPass_Umitools_Percentage\tDeduplicated_Barcodes\tClustered_Barcodes" > $out_tab

# Process cutadapt logs
for cutadapt_log in "$cutadapt_dir"/*.clip.log; do
    sample_name=$(basename "$cutadapt_log" .clip.log)
    umitools_log="$umitools_dir/$sample_name.umi.log"
    deduplicated_barcodes="$deduplicated_dir/$sample_name.starumi"
    clustered_barcodes="$clustered_barcodes_dir/$sample_name.bc_cluster.txt"

    # Get the number of input read-pairs from cutadapt log
    input_read_pairs=$(grep "Total read pairs processed" "$cutadapt_log" | awk '{print $NF}')

    # Get the number and percentage of pass-cutadapt read-pairs
    pass_cutadapt=$(grep "Pairs written (passing filters)" "$cutadapt_log" | awk '{print $(NF-1)}')
    pass_cutadapt_percentage=$(grep "Pairs written (passing filters)" "$cutadapt_log" | awk '{gsub(/[\(\)]/,""); print $NF}')

    # Get the number and percentage of pass-umitools read-pairs
    pass_umitools=$(grep "Reads output" "$umitools_log" | awk '{print $NF}')
    pass_umitools_percentage=$(echo "scale=2; ($pass_umitools / $input_read_pairs) * 100" | bc)
    pass_umitools_percentage="${pass_umitools_percentage}%"

    # Get the number of deduplicated barcodes
    deduplicated_barcode_count=$(wc -l < "$deduplicated_barcodes")

    # Get the number of clustered barcodes
    clustered_barcode_count=$(($(wc -l < "$clustered_barcodes") - 1))

    # Append to the summary table
    echo -e "$sample_name\t$input_read_pairs\t$pass_cutadapt\t$pass_cutadapt_percentage\t$pass_umitools\t$pass_umitools_percentage\t$deduplicated_barcode_count\t$clustered_barcode_count" >> $out_tab
done

echo "Summary table generated: $out_tab"
