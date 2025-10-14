import streamlit as st
import subprocess
import tkinter as tk
from tkinter import filedialog
import os

def convert_windows_to_wsl_path(windows_path):
    """Convertit un chemin Windows (C:\\path) en chemin WSL (/mnt/c/path)"""
    if not windows_path:
        return ""
    
    # Remplace les backslashes par des slashes
    path = windows_path.replace("\\", "/")
    
    # Détecte si c'est un chemin Windows avec lettre de lecteur
    if len(path) >= 2 and path[1] == ":":
        drive_letter = path[0].lower()
        path_without_drive = path[2:]
        wsl_path = f"/mnt/{drive_letter}{path_without_drive}"
    else:
        wsl_path = path
    
    # Assure qu'il se termine par /
    if not wsl_path.endswith("/"):
        wsl_path += "/"
    
    return wsl_path

def select_folder():
    """Ouvre une fenêtre de sélection de dossier"""
    root = tk.Tk()
    root.withdraw()  # Cache la fenêtre principale
    root.wm_attributes('-topmost', 1)  # Met la fenêtre au premier plan
    folder_path = filedialog.askdirectory(master=root)
    root.destroy()
    return folder_path

st.title("Setup & Analyse")

# Champs pour les paramètres de l'analyse
st.subheader("Run Analysis")

# Initialiser les valeurs dans session_state si elles n'existent pas
if 'param1_value' not in st.session_state:
    st.session_state.param1_value = ""
if 'param2_value' not in st.session_state:
    st.session_state.param2_value = ""
if 'param5_value' not in st.session_state:
    st.session_state.param5_value = ""

# Param1 - Dossier de travail
col1, col2 = st.columns([4, 1])
with col1:
    param1 = st.text_input(
        "Dossier travail", 
        value=st.session_state.param1_value,
        placeholder="/mnt/c/etc/dossier_travail/",
        key="param1_input",
        help="Remplacer les débuts de chemin : C:/ par /mnt/c/"
    )
with col2:
    st.write("")  # Espace pour aligner avec le text_input
    st.write("")
    if st.button("📁", key="btn1"):
        folder = select_folder()
        if folder:
            converted_path = convert_windows_to_wsl_path(folder)
            st.session_state.param1_value = converted_path
            st.rerun()

# Param2 - Dossier genome
col3, col4 = st.columns([4, 1])
with col3:
    param2 = st.text_input(
        "Dossier genome (ou telecharger)", 
        value=st.session_state.param2_value,
        placeholder="telecharger OU /mnt/c/etc/dossier_travail/genome_telechargé_et_indexé/",
        key="param2_input"
    )
with col4:
    st.write("")
    st.write("")
    if st.button("📁", key="btn2"):
        folder = select_folder()
        if folder:
            converted_path = convert_windows_to_wsl_path(folder)
            st.session_state.param2_value = converted_path
            st.rerun()

# Param3 & 4 - URLs (pas de sélecteur de dossier)
param3 = st.text_input(
    "URL genome fasta", 
    value="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.fna.gz"
)
param4 = st.text_input(
    "URL genome gtf", 
    value="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic.gtf.gz"
)


# Param5 - Dossier reads
col5, col6 = st.columns([4, 1])
with col5:
    param5 = st.text_input(
        "Dossier reads (ou telecharger)", 
        value=st.session_state.param5_value,
        placeholder="telecharger OU /mnt/c/etc/dossier_travail/reads/",
        key="param5_input"
    )
with col6:
    st.write("")
    st.write("")
    if st.button("📁", key="btn6"):
        folder = select_folder()
        if folder:
            converted_path = convert_windows_to_wsl_path(folder)
            st.session_state.param5_value = converted_path
            st.rerun()

# Paramètres restants
param6 = st.text_input(
    "Nom base projet", 
    placeholder="PRJ_xxxxxxx_Ovaries    > créer un sous dossier : /mnt/c/etc/dossier_travail/PRJ_xxxxxxx_Ovaries/"
)
param7 = st.text_input(
    "Liste SRA", 
    placeholder='laisser "" si on telecharge les SRA, sinon :"SRRXXXXXX1 SRRXXXXXX2" mettre "" autour'
)
param8 = st.text_input(
    "Technologie de séquençage short long", 
    placeholder="short ou long"
)
param9 = st.text_input(
    "Single or pair end ?", 
    placeholder="single ou pair"
)

if st.button("Launch Analysis"):
    cmd = f"bash alignement.sh {param1} {param2} {param3} {param4} {param5} {param6} {param7} {param8} {param9}"
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

# import webbrowser
# URL locale de Streamlit
# url = "http://localhost:8501"
# Ouvre le navigateur par défaut
# webbrowser.open(url)