DOSSIER_TRAVAIL=$1
DOSSIER_GENOME_TRAVAIL=$2
url_genome=$3

DOSSIER_READS_TRAVAIL=$4
NOM_BASE_PROJET=$5
liste_sra_a_telecharger=$6
technologie_de_sequencage=$7
single_or_pair_end=$8




#####################################################################

url_genome_fna=${url_genome}.fna.gz
url_genome_gtf=${url_genome}.gtf.gz



#Creation du dossier des travails , et des sous dossiers
cd --
#nom de la matrice d'alignement :
nom_matrice_alignement="${NOM_BASE_PROJET}_${technologie_de_sequencage}_${single_or_pair_end}_counts.txt"
DOSSIER_TRAVAIL_projet="${DOSSIER_TRAVAIL}${NOM_BASE_PROJET}/"

#genome fasta et gtf 

#url_genome_fna=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.fna.gz
#url_genome_gtf=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.gtf.gz


# Extraction du nom de fichier sans .gz
nom_genome=$(basename "$url_genome_fna" .gz)
nom_genome_annotation=$(basename "$url_genome_gtf" .gz)

# Vérification
echo "nom_genome = $nom_genome"
echo "nom_genome_annotation = $nom_genome_annotation"



DOSSIER_STATS=${DOSSIER_TRAVAIL_projet}STATS/
DOSSIER_SORTED_BAM_and_INDEX=${DOSSIER_TRAVAIL_projet}SORTED_BAM_AND_INDEX/
DOSSIER_COUNTS=${DOSSIER_TRAVAIL_projet}COUNTS/

tableau_alignements=${DOSSIER_COUNTS}${nom_matrice_alignement}
liste_alignements=()

mkdir "${DOSSIER_TRAVAIL[@]}"
mkdir "${DOSSIER_TRAVAIL_projet[@]}"


mkdir "${DOSSIER_STATS[@]}"

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
        
        # Téléchargements parallèles avec wget
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_gtf} &
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_fna} &
        wait
        
        # Décompression
        gunzip "${DOSSIER_GENOME_TRAVAIL[@]}/"*
        
        # Indexation avec threads
        minimap2 -t 28 -d "${genome_index[@]}" "${genome[@]}"
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
        
        # Téléchargements parallèles avec wget
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_gtf} &
        wget -P $DOSSIER_GENOME_TRAVAIL ${url_genome_fna} &
        wait
        
        # Décompression
        gunzip "${DOSSIER_GENOME_TRAVAIL[@]}/"*
        
        # Extraction parallèle des splicesites et exons
        hisat2_extract_splice_sites.py "${genome_annotation_gtf[@]}" > "${splicesites[@]}" &
        hisat2_extract_exons.py "${genome_annotation_gtf[@]}" > "${exons[@]}" &
        wait
        
        # Indexation avec threads
        hisat2-build -p 28 --ss "${splicesites[@]}" --exon "${exons[@]}" "${genome[@]}" "${genome_index[@]}"
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
# Télécharge sra
if [ ${DOSSIER_READS_TRAVAIL[@]} == "telecharger" ]
then
    DOSSIER_READS_TRAVAIL=${DOSSIER_TRAVAIL_projet}SRA/
    mkdir -p "${DOSSIER_READS_TRAVAIL[@]}"
    echo $liste_sra_a_telecharger
    echo "telechargement des sra"
    
    # Téléchargement parallèle des SRA (max 4 en parallèle pour ne pas surcharger)
    max_parallel=4
    count=0
    for sra in $liste_sra_a_telecharger;
    do
        echo $sra
        # fasterq-dump avec threads et split-3 pour pair-end
        fasterq-dump $sra -O "${DOSSIER_READS_TRAVAIL[@]}" -e 8 --split-3 &
        
        ((count++))
        # Attendre tous les max_parallel téléchargements avant de continuer
        if [ $((count % max_parallel)) -eq 0 ]; then
            wait
        fi
    done
    wait  # Attendre les derniers téléchargements
fi

echo -e "Les reads sont dans le dossier : $DOSSIER_READS_TRAVAIL \n"
ls $DOSSIER_READS_TRAVAIL

# Détection automatique de l'extension FASTQ
echo "Détection de l'extension des fichiers..."
if ls "${DOSSIER_READS_TRAVAIL}"*.fastq 1> /dev/null 2>&1; then
    extension=".fastq"
    echo "Extension détectée : .fastq"
elif ls "${DOSSIER_READS_TRAVAIL}"*.fq 1> /dev/null 2>&1; then
    extension=".fq"
    echo "Extension détectée : .fq"
elif ls "${DOSSIER_READS_TRAVAIL}"*.fastq.gz 1> /dev/null 2>&1; then
    extension=".fastq.gz"
    echo "Extension détectée : .fastq.gz"
elif ls "${DOSSIER_READS_TRAVAIL}"*.fq.gz 1> /dev/null 2>&1; then
    extension=".fq.gz"
    echo "Extension détectée : .fq.gz"
else
    echo "ERREUR : Aucun fichier FASTQ trouvé dans ${DOSSIER_READS_TRAVAIL}"
    exit 1
fi

# Récupère la liste des reads dans le dossier - SINGLE READS
if [ $single_or_pair_end == "single" ]
then
    readarray -t liste_de_reads < <(
        ls "${DOSSIER_READS_TRAVAIL[@]}"*${extension} | sed "s|${DOSSIER_READS_TRAVAIL[@]}||" | sed "s|${extension}||" | sort -u
    )
    echo "Reads single-end détectés : ${liste_de_reads[@]}"
fi

# PAIR-END READS
if [ $single_or_pair_end == "pair" ]
then
    readarray -t liste_de_reads < <(
        ls "${DOSSIER_READS_TRAVAIL[@]}"*${extension} | sed "s|${DOSSIER_READS_TRAVAIL[@]}||" | sed "s|[_]?[12]${extension}||" | sort -u
    )
    echo "Reads pair-end détectés : ${liste_de_reads[@]}"
fi
#####################################################################

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
    
    # Pipeline optimisé : hisat2 -> samtools view -> samtools sort en un seul flux
    hisat2 -p 28 -x "${DOSSIER_GENOME_TRAVAIL[@]}${nom_genome}.idx" --dta --rna-strandness R -U "${DOSSIER_READS_TRAVAIL[@]}/${reads}" | \
    samtools view -@ 8 -Sb - | \
    samtools sort -@ 8 -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam" -
    
    # Index en parallèle
    samtools index -@ 4 "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    
    # Stats si nécessaire (optionnel)
    samtools flagstat -@ 4 "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam" > "${DOSSIER_STATS[@]}${alignement}.stats.txt"
    
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
    
    # Pipeline optimisé : hisat2 -> samtools view -> samtools sort (par coordonnées directement)
    hisat2 -p 28 -x "${DOSSIER_GENOME_TRAVAIL[@]}${nom_genome}.idx" --dta --rna-strandness RF \
    -1 "${DOSSIER_READS_TRAVAIL[@]}/${reads1[@]}" -2 "${DOSSIER_READS_TRAVAIL[@]}/${reads2[@]}" | \
    samtools view -@ 8 -Sb - | \
    samtools sort -@ 8 -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam" -
    
    # Index en parallèle
    samtools index -@ 4 "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    
    liste_alignements+=("${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam")
done
fi
################################################################################################
echo "$single_or_pair_end"
if [[ "$technologie_de_sequencage" == "long" && "$single_or_pair_end" == "single" ]]
then
echo "alignement long reads single end"
for nom_reads in "${liste_de_reads[@]}";
do
    reads="${DOSSIER_READS_TRAVAIL[@]}${nom_reads}${extension}"
    alignement=${nom_genome}.VS.${nom_reads}
    
    # Pipeline optimisé : minimap2 -> samtools view -> samtools sort en un seul flux
    minimap2 -ax splice -t 28 "${genome[@]}" "${reads[@]}" | \
    samtools view -@ 8 -Sb - | \
    samtools sort -@ 8 -o "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam" -
    
    # Index en parallèle
    samtools index -@ 4 "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam"
    
    # Stats si nécessaire (optionnel, peut être commenté pour gagner du temps)
    samtools flagstat -@ 4 "${DOSSIER_SORTED_BAM_and_INDEX[@]}${alignement}.sorted.bam" > "${DOSSIER_STATS[@]}${alignement}.stats.txt"
    
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