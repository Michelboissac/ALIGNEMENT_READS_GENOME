# ALIGNEMENT_READS_GENOME



1) installer wsl2 Ubuntu avec le manuel d'installation de wsl2 : https://github.com/Michelboissac/install_wsl2_conda
, puis ouvrir ubuntu, installer conda, et creer l'environnement conda TOOLS_env :

conda create --yes -n TOOLS_env -c bioconda -c conda-forge \
    python=3.10 \
    samtools=1.13 \
    minimap2=2.22 \
    hisat2=2.2.1 \
    subread=2.0.1 \
    sra-tools=3.2.1

2)activer l'environnement avec la commande :
conda activate TOOLS_env

(à faire une seule fois : pip install streamlit) 
 pip install streamlit

3)vous pouvez fermer le terminal de commande et cliquez sur alignements.bat, cela va ouvrir la page web

Troobleshooting :
-verifier avec la commande wsl -l -v dans un terminal de commande windows, que Ubuntu est bien installé
-verifier que le chemin ou est installé conda correspond à ~/miniconda3/etc/profile.d/conda.sh
faire : ls ~/miniconda3/etc/profile.d/conda.sh



3bis) (si le.bat ne marche vraiment pas) ouvrir un terminal Ubuntu, avec la commande "cd", se deplacer dans le repertoire de ce github telechargé 
(attention les noms de repertoires en linux ne sont pas de la forme : 
C:/dossier1/dossier2/etc mais de la forme :  /mnt/c/dossier1/dossier2/etc
une fois dans le repertoire lancer le script python de la maniere suivante :

streamlit run script.py


COMMANDES UTILES LINUX: 
    pour voir dans quel repertoire on se trouve :
    pwd

    pour lister les elements d'un repertoire :
    ls /mnt/c/dossier1/dossier2/etc
    
    pour revenenir à la racine :
    cd --

    pour se deplacer dans un un dossier:
    cd /mnt/c/dossier1/dossier2/etc



pour analyser une matrice d'alignement : https://github.com/Michelboissac/ANALYSE_MATRICE_ALIGNEMENT
