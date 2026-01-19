# --- STAGE 1 : BUILDER (L'image de travail) ---
FROM python:3.11-slim as builder

# 1. Install des outils de compilation (LOURD mais nécessaire uniquement ici)
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libspatialindex-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Création d'un environnement virtuel (pour isoler les libs)
RUN python -m venv /opt/venv
# On active l'environnement pour les commandes suivantes
ENV PATH="/opt/venv/bin:$PATH"

# 3. Clone "Super Léger" (Depth 1 = Pas d'historique git)
# Cela évite de télécharger les 200Mo d'historique du repo
RUN git clone --depth 1 https://github.com/cthonney/maptoposter-docker.git .

# 4. Installation des dépendances Python dans le venv
RUN pip install --no-cache-dir -r requirements.txt


# --- STAGE 2 : FINAL (L'image de production) ---
FROM python:3.10-slim

# 1. On installe juste le minimum vital pour l'exécution (Runtime)
# libspatialindex-c6 est la version légère requise par Rtree/OSMnx
RUN apt-get update && apt-get install -y \
    libspatialindex-c6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. On copie l'environnement virtuel préparé dans le Stage 1
COPY --from=builder /opt/venv /opt/venv

# 3. On copie le code préparé dans le Stage 1
# On exclut explicitement le dossier .git s'il traîne encore
COPY --from=builder /app /app
RUN rm -rf /app/.git

# 4. Configuration de l'environnement
ENV PATH="/opt/venv/bin:$PATH"
ENV MPLBACKEND=Agg

EXPOSE 5025

CMD ["python", "app.py"]