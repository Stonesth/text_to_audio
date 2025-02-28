#!/bin/bash

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration de la journalisation
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/update_numpy_log.txt"

# Création du répertoire de logs si nécessaire
mkdir -p "$LOG_DIR"

# Initialisation du fichier de log
echo "===== DEBUT MISE A JOUR NUMPY $(date) =====" > "$LOG_FILE"

# Fonction de journalisation
log() {
    local level="$1"
    local message="$2"
    echo "[$(date)] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERREUR]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[AVERTISSEMENT]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCÈS]${NC} $message"
            ;;
        *)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
    esac
}

# Fonction d'exécution de commande avec journalisation
exec_and_log() {
    local command="$1"
    local description="$2"
    
    echo "[$(date)] [COMMANDE] $command" >> "$LOG_FILE"
    echo -e "${BLUE}Exécution:${NC} $command"
    
    eval "$command" >> "$LOG_FILE" 2>&1
    local result=$?
    
    if [ $result -ne 0 ]; then
        log "ERROR" "Échec de la commande: $command"
        log "ERROR" "Code d'erreur: $result"
        return $result
    else
        log "SUCCESS" "$description réussi"
        return 0
    fi
}

# Affichage de l'en-tête
echo -e "${BLUE}===== MISE A JOUR DE NUMPY =====${NC}"
echo -e "Script de mise à jour de NumPy pour résoudre les incompatibilités avec PyTorch"
echo -e "Date et heure: $(date)"
echo -e "${BLUE}==============================${NC}"

# Vérification de Python
log "INFO" "Vérification de l'installation Python..."
if ! command -v python3 &> /dev/null; then
    log "ERROR" "Python n'est pas installé ou n'est pas dans le PATH"
    echo "Python n'est pas installé ou n'est pas dans le PATH."
    echo "Veuillez installer Python ou vérifier votre PATH."
    read -p "Appuyez sur Entrée pour continuer..."
    exit 1
fi

# Affichage de la version de Python
PYTHON_VERSION=$(python3 --version 2>&1)
log "INFO" "Version Python détectée: $PYTHON_VERSION"
echo -e "Version Python détectée: $PYTHON_VERSION"

# Vérification de l'environnement virtuel
VENV_STATUS=$(python3 -c "import sys; print('Environnement virtuel: ' + (sys.prefix if hasattr(sys, 'real_prefix') or sys.prefix != sys.base_prefix else 'Non'))")
log "INFO" "$VENV_STATUS"
echo -e "$VENV_STATUS"

# Vérification de la version actuelle de NumPy
log "INFO" "Vérification de la version actuelle de NumPy..."
if ! python3 -c "import numpy" &> /dev/null; then
    log "WARNING" "NumPy n'est pas installé ou ne peut pas être importé"
    echo "NumPy n'est pas installé ou ne peut pas être importé."
    CURRENT_NUMPY_VERSION="Non installé"
else
    CURRENT_NUMPY_VERSION=$(python3 -c "import numpy; print('Version NumPy actuelle:', numpy.__version__)")
fi
log "INFO" "$CURRENT_NUMPY_VERSION"
echo -e "$CURRENT_NUMPY_VERSION"

# Mise à jour de NumPy
echo
echo -e "${BLUE}==============================${NC}"
echo -e "Mise à jour de NumPy vers la version 1.24.3..."
echo -e "Cette version est compatible avec PyTorch et devrait résoudre les avertissements."
echo -e "${BLUE}==============================${NC}"
echo

# Demande de confirmation
read -p "Voulez-vous continuer avec la mise à jour? (O/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Oo]$ ]]; then
    log "INFO" "Mise à jour annulée par l'utilisateur"
    echo "Mise à jour annulée."
    read -p "Appuyez sur Entrée pour continuer..."
    exit 0
fi

# Mise à jour de pip
log "INFO" "Mise à jour de pip..."
exec_and_log "python3 -m pip install --upgrade pip --no-cache-dir" "Mise à jour de pip"

# Installation de NumPy 1.24.3
log "INFO" "Installation de NumPy 1.24.3..."
exec_and_log "python3 -m pip install numpy==1.24.3 --no-cache-dir" "Installation de NumPy 1.24.3"
if [ $? -ne 0 ]; then
    log "ERROR" "Échec de l'installation de NumPy 1.24.3"
    echo
    echo "Échec de l'installation de NumPy 1.24.3."
    echo "Veuillez vérifier les logs pour plus de détails: $LOG_FILE"
    read -p "Appuyez sur Entrée pour continuer..."
    exit 1
fi

# Vérification de la nouvelle version de NumPy
log "INFO" "Vérification de la nouvelle version de NumPy..."
if ! python3 -c "import numpy" &> /dev/null; then
    log "ERROR" "Impossible de vérifier la nouvelle version de NumPy"
    echo "Impossible de vérifier la nouvelle version de NumPy."
else
    NEW_NUMPY_VERSION=$(python3 -c "import numpy; print('Nouvelle version NumPy:', numpy.__version__)")
    log "SUCCESS" "$NEW_NUMPY_VERSION"
    echo -e "$NEW_NUMPY_VERSION"
fi

# Fin du script
echo
echo -e "${BLUE}==============================${NC}"
echo -e "${GREEN}Mise à jour terminée avec succès!${NC}"
echo -e "Vous pouvez maintenant lancer l'application sans les avertissements NumPy."
echo -e "${BLUE}==============================${NC}"
echo
log "INFO" "Mise à jour NumPy terminée"

read -p "Appuyez sur Entrée pour continuer..."
exit 0
