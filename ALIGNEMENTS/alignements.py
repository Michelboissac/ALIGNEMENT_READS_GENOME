import streamlit as st
import subprocess
import re

def convert_to_wsl_path(path):
    """Convertit un chemin Windows en chemin WSL"""
    if not path or path.strip() == "":
        return ""
    
    path = path.strip()
    
    # Remplacer les backslashes par des slashes
    path = path.replace("\\", "/")
    
    # Détecter et convertir les chemins Windows (C:, D:, etc.)
    # Pattern: lettre: suivi de / ou \
    match = re.match(r'^([A-Za-z]):', path)
    if match:
        drive_letter = match.group(1).lower()
        path_without_drive = path[2:]  # Enlever "C:"
        wsl_path = f"/mnt/{drive_letter}{path_without_drive}"
    else:
        wsl_path = path
    
    # Assurer qu'il se termine par /
    if wsl_path and not wsl_path.endswith("/"):
        wsl_path += "/"
    
    return wsl_path

st.title("Setup & Analyse")

# Champs pour les paramètres de l'analyse
st.subheader("Run Analysis")

# --- Initialisation des clés de session ---
for key in ["param1_value", "param2_value", "param4_value"]:
    if key not in st.session_state:
        st.session_state[key] = ""

# Param1 - Dossier de travail
param1_raw = st.text_input(
    "Dossier travail", 
    value=st.session_state.param1_value,
    placeholder="/mnt/c/etc/dossier_travail/ ou C:\\Users\\...",
    key="param1_input",
    help="Tapez un chemin Windows (C:\\...) ou WSL (/mnt/c/...), il sera converti automatiquement"
)
param1 = convert_to_wsl_path(param1_raw)
if param1_raw and param1 != param1_raw:
    st.caption(f"✓ Converti en : `{param1}`")

# Param2 - Dossier genome
param2_raw = st.text_input(
    "Dossier genome (ou telecharger)", 
    value=st.session_state.param2_value,
    placeholder='telecharger OU /mnt/c/etc/genome/ ou C:\\Users\\...',
    key="param2_input"
)
param2 = convert_to_wsl_path(param2_raw)
if param2_raw and param2 != param2_raw:
    st.caption(f"✓ Converti en : `{param2}`")

# Param3 - Sélection du génome
genome_options = {
    "Apis mellifera": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/254/395/GCF_003254395.2_Amel_HAv3.1/GCF_003254395.2_Amel_HAv3.1_genomic",
    "Drosophila melanogaster": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/215/GCF_000001215.4_Release_6_plus_ISO1_MT/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic",
    "Varroa destructor": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/443/255/GCF_002443255.2_Vdes_3.0/GCF_002443255.2_Vdes_3.0_genomic",
    "Mus musculus": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/635/GCF_000001635.27_GRCm39/GCF_000001635.27_GRCm39_genomic",
    "Human": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic",
    "Vespa velutina": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/912/470/025/GCF_912470025.1_iVesVel2.1/GCF_912470025.1_iVesVel2.1_genomic",
    "Monomorium pharaonis": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/013/373/865/GCF_013373865.1_ASM1337386v2/GCF_013373865.1_ASM1337386v2_genomic",
    "Aphis gossypii": "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/020/184/175/GCF_020184175.1_ASM2018417v2/GCF_020184175.1_ASM2018417v2_genomic",
    "Autre (saisir URL)": ""
}

genome_choice = st.selectbox(
    "Sélectionner le génome",
    options=list(genome_options.keys()),
    index=0
)

# Si "Autre", afficher le champ de saisie, sinon utiliser l'URL prédéfinie
if genome_choice == "Autre (saisir URL)":
    param3 = st.text_input(
        "URL genome personnalisée (sans extension)",
        placeholder="https://ftp.ncbi.nlm.nih.gov/.../genome_genomic"
    )
else:
    param3 = genome_options[genome_choice]
    st.caption(f"URL sélectionnée : `{param3}`")

# param4 - Dossier reads
param4_raw = st.text_input(
    "Dossier reads (ou telecharger)", 
    value=st.session_state.param4_value,
    placeholder='telecharger OU /mnt/c/etc/reads/ ou C:\\Users\\...',
    key="param4_input"
)
param4 = convert_to_wsl_path(param4_raw)
if param4_raw and param4 != param4_raw:
    st.caption(f"✓ Converti en : `{param4}`")

# Paramètres restants
param5 = st.text_input(
    "Nom base projet", 
    placeholder="PRJ_xxxxxxx_Ovaries"
)

param6 = st.text_input(
    "Liste SRA", 
    placeholder='laisser vide si téléchargement auto, sinon : "SRRXXXXXX1 SRRXXXXXX2"'
)

param7 = st.selectbox(
    "Technologie de séquençage",
    options=["short", "long"],
    index=0
)

param8 = st.selectbox(
    "Type de reads",
    options=["pair", "single"],
    index=0
)

# Afficher un résumé avant lancement
st.subheader("Résumé des paramètres")
with st.expander("Voir les paramètres", expanded=False):
    st.write(f"**Dossier travail :** `{param1}`")
    st.write(f"**Dossier genome :** `{param2}`")
    st.write(f"**Génome :** {genome_choice}")
    st.write(f"**URL genome :** `{param3}`")
    st.write(f"**Dossier reads :** `{param4}`")
    st.write(f"**Nom projet :** `{param5}`")
    st.write(f"**Liste SRA :** `{param6}`")
    st.write(f"**Technologie :** `{param7}`")
    st.write(f"**Type reads :** `{param8}`")

# Validation des champs obligatoires
if st.button("Launch Analysis", type="primary"):
    # Vérifier les champs obligatoires
    errors = []
    if not param1:
        errors.append("Le dossier de travail est obligatoire")
    if not param2:
        errors.append("Le dossier genome est obligatoire")
    if not param3:
        errors.append("L'URL du génome est obligatoire")
    if not param4:
        errors.append("Le dossier reads est obligatoire")
    if not param5:
        errors.append("Le nom du projet est obligatoire")
    
    if errors:
        for error in errors:
            st.error(f"❌ {error}")
    else:
        # Construction de la commande
        # Note: param3 contient l'URL de base sans extension
        # Votre script bash devra ajouter .fna.gz et .gtf.gz
        cmd = f'bash alignement.sh "{param1}" "{param2}" "{param3}" "{param4}" "{param5}" "{param6}" "{param7}" "{param8}"'
        
        st.info(f"🚀 Lancement de l'analyse...")
        st.code(cmd, language="bash")
        
        try:
            # Exécuter la commande
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                cwd=param1 if param1 else None
            )
            
            if result.returncode == 0:
                st.success("✅ Analysis complete!")
                if result.stdout:
                    with st.expander("Voir la sortie standard", expanded=True):
                        st.text(result.stdout)
            else:
                st.error(f"❌ Erreur lors de l'exécution (code: {result.returncode})")
                if result.stderr:
                    with st.expander("Voir les erreurs", expanded=True):
                        st.text(result.stderr)
                if result.stdout:
                    with st.expander("Voir la sortie standard"):
                        st.text(result.stdout)
                        
        except Exception as e:
            st.error(f"❌ Exception lors de l'exécution : {e}")

# Note d'information
st.markdown("---")
st.caption("💡 Les chemins Windows (C:\\...) sont automatiquement convertis en chemins WSL (/mnt/c/...)")
st.caption("💡 L'URL du génome est construite automatiquement selon votre sélection")