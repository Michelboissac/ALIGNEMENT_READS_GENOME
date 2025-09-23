DOSSIER_TRAVAIL=$1
DOSSIER_GENOME_TRAVAIL=$2
extension=$3
DOSSIER_READS_TRAVAIL=$4
NOM_BASE_PROJET=$5
liste_sra_a_telecharger=$6
technologie_de_sequencage=$7
single_or_pair_end=$8



#####################################################################
#Creation du dossier des travails , et des sous dossiers
cd --
#nom de la matrice d'alignement :
nom_matrice_alignement="${NOM_BASE_PROJET}_${technologie_de_sequencage}_${single_or_pair_end}_counts.txt"
DOSSIER_TRAVAIL_projet="${DOSSIER_TRAVAIL}${NOM_BASE_PROJET}/"

#genome fasta
nom_genome=GCF_003254395.2_Amel_HAv3.1_genomic.fna
url_genome_fna=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.fna.gz

#genome annotation gtf
nom_genome_annotation=GCF_003254395.2_Amel_HAv3.1_genomic.gtf
url_genome_gtf=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.gtf.gz


DOSSIER_SAM=${DOSSIER_TRAVAIL_projet}SAM/
DOSSIER_SAM_STATS=${DOSSIER_TRAVAIL_projet}SAM_STATS/

DOSSIER_BAM=${DOSSIER_TRAVAIL_projet}BAM/
DOSSIER_SORTED_BAM_and_INDEX=${DOSSIER_TRAVAIL_projet}SORTED_BAM_AND_INDEX/
DOSSIER_COUNTS=${DOSSIER_TRAVAIL_projet}COUNTS/

tableau_alignements=${DOSSIER_COUNTS}${nom_matrice_alignement}
liste_alignements=()

mkdir "${DOSSIER_TRAVAIL[@]}"
mkdir "${DOSSIER_TRAVAIL_projet[@]}"

mkdir "${DOSSIER_SAM[@]}"
mkdir "${DOSSIER_SAM_STATS[@]}"
mkdir "${DOSSIER_BAM[@]}"
mkdir "${DOSSIER_SORTED_BAM_and_INDEX[@]}"
mkdir "${DOSSIER_COUNTS[@]}"


cd $DOSSIER_TRAVAIL_projet





#####################################################################
#telecharge genome illumina

echo $technologie_de_sequencage
echo ${DOSSIER_GENOME_TRAVAIL[@]}

if [ ${DOSSIER_GENOME_TRAVAIL[@]} == "telecharger" ]
then

    echo "Telechargement du genome fasta, et des annotations gtf"

    #
    #indexation :
    if [ $technologie_de_sequencage == "long" ]
    then
        echo "telechargement et indexation du genome pour un alignement des long reads avec minimap2"
        DOSSIER_GENOME_TRAVAIL=${DOSSIER_TRAVAIL}GENOME_index_minimap2_long_reads/
        genome=${DOSSIER_GENOME_TRAVAIL}${nom_genome}
        genome_index=${DOSSIER_GENOME_TRAVAIL}${nom_genome}.idx
        genome_annotation_gtf=${DOSSIER_GENOME_TRAVAIL}${nom_genome_annotation}


        mkdir "${DOSSIER_GENOME_TRAVAIL[@]}"
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_gtf}
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_fna}

        gunzip "${DOSSIER_GENOME_TRAVAIL[@]}/"*

        minimap2 -d "${genome_index[@]}" "${genome[@]}"
    fi



    if [ $technologie_de_sequencage == "short" ]
    then
        echo "telechargement et indexation du genome pour un alignement des shorts reads avec hisat2"
        DOSSIER_GENOME_TRAVAIL=${DOSSIER_TRAVAIL}GENOME_index_hisat2_shorts_reads/
        genome=${DOSSIER_GENOME_TRAVAIL}${nom_genome}
        genome_index=${DOSSIER_GENOME_TRAVAIL}${nom_genome}.idx
        genome_annotation_gtf=${DOSSIER_GENOME_TRAVAIL}${nom_genome_annotation}
        splicesites=${DOSSIER_GENOME_TRAVAIL}splicesites.txt
        exons=${DOSSIER_GENOME_TRAVAIL}exons.txt

        mkdir "${DOSSIER_GENOME_TRAVAIL[@]}"

        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_gtf}
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_fna}

        gunzip "${DOSSIER_GENOME_TRAVAIL[@]}/"*

        hisat2_extract_splice_sites.py "${genome_annotation_gtf[@]}" > "${splicesites[@]}"
        hisat2_extract_exons.py "${genome_annotation_gtf[@]}" > "${exons[@]}"
        hisat2-build --ss "${splicesites[@]}" --exon "${exons[@]}" "${genome[@]}" "${genome_index[@]}"
    fi


else
   echo "genome deja telechargé et indéxé"

    genome=${DOSSIER_GENOME_TRAVAIL}${nom_genome}
    genome_index=${DOSSIER_GENOME_TRAVAIL}${nom_genome}.idx
    genome_annotation_gtf=${DOSSIER_GENOME_TRAVAIL}${nom_genome_annotation}

    #hisat2 shorts reads illumina
    splicesites=${DOSSIER_GENOME_TRAVAIL}splicesites.txt
    exons=${DOSSIER_GENOME_TRAVAIL}exons.txt
fi

echo -e "Le genome, annotation gtf, et index, exons et splicesites sont dans le repertoire : ${DOSSIER_GENOME_TRAVAIL[@]} \n"
ls $DOSSIER_GENOME_TRAVAIL


#####################################################################
#telecharge sra

if [ ${DOSSIER_READS_TRAVAIL[@]} == "telecharger" ]
then
    DOSSIER_READS_TRAVAIL=${DOSSIER_TRAVAIL_projet}SRA/
    mkdir "${DOSSIER_READS_TRAVAIL[@]}"
    echo $liste_sra_a_telecharger
    echo "telechargement des sra"
    for sra in $liste_sra_a_telecharger;
    do
        echo $sra
        fasterq-dump $sra -O "${DOSSIER_READS_TRAVAIL[@]}" -p
    done
fi

echo -e "Les reads sont dans le dossier :  $DOSSIER_READS_TRAVAIL \n"
ls $DOSSIER_READS_TRAVAIL


#Recupere la liste des sra.fastq dans le dossier SRA  SINGLE READS
if [ $single_or_pair_end == "single" ]
then
readarray -t liste_de_reads < <(
    ls "${DOSSIER_READS_TRAVAIL[@]}"*${extension} | sed "s|${DOSSIER_READS_TRAVAIL[@]}||" | sed "s|${extension}||" | sort -u
)
echo "${liste_de_reads[@]}"
fi


if [ $single_or_pair_end == "pair" ]
then
readarray -t liste_de_reads < <(
  ls "${DOSSIER_READS_TRAVAIL[@]}"*${extension}|sed "s|${DOSSIER_READS_TRAVAIL[@]}||"|sed "s|[1-2]${extension}||"|sort -u
)
echo "${liste_de_reads[@]}"
fi


#ALIGNEMENTS
################################################################################################
if [[ "$technologie_de_sequencage" == "short" && "$single_or_pair_end" == "single" ]]
then
echo "alignement short reads single end"
echo $DOSSIER_TRAVAIL_projet
for nom_reads in "${liste_de_reads[@]}"; do
    reads="${nom_reads}${extension}"
    alignement=${nom_genome}.VS.${nom_reads}
    cd "${DOSSIER_TRAVAIL_projet[@]}"
    hisat2 -x "${DOSSIER_GENOME_TRAVAIL[@]}${nom_genome}.idx" --dta --rna-strandness R -U "${DOSSIER_READS_TRAVAIL[@]}/${reads}" -S SAM/${alignement}.sam
    samtools flagstats "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_SAM_STATS[@]}${alignement}.sam.stats.txt"
    samtools view -Sb "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_BAM[@]}${alignement}.bam"
    samtools sort "${DOSSIER_BAM[@]}${alignement}.bam" -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    samtools index "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    liste_alignements+=("${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam")
done
fi
################################################################################################

if [[ "$technologie_de_sequencage" == "short" && "$single_or_pair_end" == "pair" ]]
then
echo "alignement short reads pair end"
echo $DOSSIER_TRAVAIL_projet
for nom_reads in "${liste_de_reads[@]}"; do
    reads1="${nom_reads}1${extension}"
    reads2="${nom_reads}2${extension}"
    alignement=${nom_genome}.VS.${nom_reads}
    cd "${DOSSIER_TRAVAIL_projet[@]}"
    echo "${DOSSIER_GENOME_TRAVAIL[@]}${nom_genome}.idx"
    hisat2 -x "${DOSSIER_GENOME_TRAVAIL[@]}${nom_genome}.idx" --dta --rna-strandness RF -1 "${DOSSIER_READS_TRAVAIL[@]}/${reads1[@]}" -2 "${DOSSIER_READS_TRAVAIL[@]}/${reads2[@]}" -S SAM/${alignement}.sam
    samtools flagstats "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_SAM_STATS[@]}${alignement}.sam.stats.txt"
    samtools view -Sb "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_BAM[@]}${alignement}.bam"
    samtools sort -n "${DOSSIER_BAM[@]}${alignement}.bam" -o "${DOSSIER_BAM[@]}${alignement}.name_sorted.bam"  # tri par nom pour fixmate
    samtools fixmate -m "${DOSSIER_BAM[@]}${alignement}.name_sorted.bam" "${DOSSIER_BAM[@]}${alignement}.name_sorted.fixmate.bam"
    samtools sort "${DOSSIER_BAM[@]}${alignement}.name_sorted.fixmate.bam" -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.name_sorted.fixmate.sorted.bam"
    samtools index "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.name_sorted.fixmate.sorted.bam"
    liste_alignements+=("${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.name_sorted.fixmate.sorted.bam")
done
fi

################################################################################################

if [[ "$technologie_de_sequencage" == "long" && "$single_or_pair_end" == "single" ]]
then
echo "alignement long reads single end"
for nom_reads in "${liste_de_reads[@]}";
do
    reads="${DOSSIER_READS_TRAVAIL[@]}${nom_reads}${extension}"
    alignement=${nom_genome}.VS.${nom_reads}
    minimap2 -ax splice "${genome[@]}" "${reads[@]}" > "${DOSSIER_SAM[@]}${alignement}.sam"
    samtools flagstats "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_SAM_STATS[@]}${alignement}.sam.stats.txt"
    samtools view -Sb "${DOSSIER_SAM[@]}${alignement}.sam" > "${DOSSIER_BAM[@]}${alignement}.bam"
    samtools sort "${DOSSIER_BAM[@]}${alignement}.bam" -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    samtools index "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    liste_alignements+=("${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam")
done
fi
################################################################################################


#CREATION DU TABLEAU COUNTS.txt
if [[ "$technologie_de_sequencage" == "short" && "$single_or_pair_end" == "single" ]]
then
    featureCounts -T 4 -t exon -g gene_id -a "${genome_annotation_gtf[@]}" -o "${tableau_alignements[@]}" "${liste_alignements[@]}"

fi

if [[ "$technologie_de_sequencage" == "short" && "$single_or_pair_end" == "pair" ]]
then
    featureCounts -T 4 -p -t exon -g gene_id -a "${genome_annotation_gtf[@]}" -o "${tableau_alignements[@]}" "${liste_alignements[@]}"

fi

if [[ "$technologie_de_sequencage" == "long" && "$single_or_pair_end" == "single" ]]
then
    featureCounts -T 4 --primary -O -t exon -g gene_id -a "${genome_annotation_gtf[@]}" -o "${tableau_alignements[@]}" "${liste_alignements[@]}"

fi