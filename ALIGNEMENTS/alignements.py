import streamlit as st
import subprocess

st.title("Setup & Analyse")

# Champs pour les paramètres de l'analyse
st.subheader("Run Analysis")
param1 = st.text_input("dossier travail", placeholder="/mnt/c/etc/dossier_travail/  remplacer les debuts de chemin : C:/ par /mnt/c/")
param2 = st.text_input("dossier genome (ou telecharger)", placeholder="telecharger OU /mnt/c/etc/dossier_travail/genome_telechargé_et_indexé/")
param3 = st.text_input("extension", placeholder=".fastq")
param4 = st.text_input("dossier reads (ou telecharger)", placeholder="telecharger OU /mnt/c/etc/dossier_travail/reads/")
param5 = st.text_input("nom base projet", placeholder="PRJ_xxxxxxx_Ovaries    > créer un sous dossier : /mnt/c/etc/dossier_travail/PRJ_xxxxxxx_Ovaries/")
param6 = st.text_input("liste SRA", placeholder="laisser \"\" si on telecharge les SRA, sinon :\"SRRXXXXXX1 SRRXXXXXX2\" metre \"\" autour")
param7 = st.text_input("technologie de séquençage short long", placeholder="short ou long")
param8 = st.text_input("single or pair end ?", placeholder="single ou pair")




if st.button("Launch Analysis"):
    cmd = f"bash alignement.sh {param1} {param2} {param3} {param4} {param5} {param6} {param7} {param8}"
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            st.success("Analysis complete!")
            st.text(result.stdout)  # affiche la sortie du script
        else:
            st.error(f"Error:\n{result.stderr}")
    except Exception as e:
        st.error(f"Exception: {e}")



import webbrowser

# URL locale de Streamlit
url = "http://localhost:8501"

# Ouvre le navigateur par défaut

#webbrowser.open(url)
