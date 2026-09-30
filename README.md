# ICTU Events

Le projet propose deux versions de la même application : Next.js et PHP. Elles utilisent la même base MySQL/MariaDB et peuvent être lancées indépendamment.

## Prérequis

- MySQL 8 ou MariaDB 10.6+
- Pour Next.js : Node.js 20.9+
- Pour PHP : PHP avec les extensions `pdo_mysql` et `mbstring` (`sudo apt install php-mbstring` sur Ubuntu/Debian)

## Préparer la base de données

À faire une seule fois, depuis la racine du dépôt. La première commande supprime puis recrée la base `ictu_events` si elle existe déjà.

```bash
sudo mysql < database/01_schema.sql && \
sudo mysql < database/02_seed_data.sql && \
sudo mysql < database/04_part4_q6_trigger_and_procedure.sql && \
sudo mysql < database/06_part6_indexes.sql && \
sudo mysql < database/07_app_user.sql
```

L’utilisateur applicatif créé par le dernier script utilise le mot de passe `ChangeMe_Ictu#2026`.

## Lancer avec Next.js

```bash
cd next-app
npm install
cp .env.example .env.local
```

Dans `next-app/.env.local`, définis `SESSION_SECRET` avec une chaîne aléatoire d’au moins 32 caractères. Ensuite :

```bash
npm run dev
```

Ouvre [http://localhost:3000](http://localhost:3000).

## Lancer avec PHP

Depuis la racine du dépôt :

```bash
DB_PASS='ChangeMe_Ictu#2026' php -S 127.0.0.1:8080 -t webapp/public
```

Ouvre [http://localhost:8080](http://localhost:8080). Garde le terminal ouvert pendant l’utilisation de l’application.

## Compte de démonstration

| Champ | Valeur |
| --- | --- |
| E-mail | `nangu@ict.edu.cm` |
| Mot de passe | `Ictu@2026` |
