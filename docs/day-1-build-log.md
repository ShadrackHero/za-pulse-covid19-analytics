# Day 1 build log — what we did, and what it means

**Date:** 26 September 2026  
**Repo:** https://github.com/ShadrackHero/za-pulse-covid19-analytics  
**Local folder:** `Desktop\za-pulse-covid19-analytics`  
**Tools used:** GitHub website, GitHub Desktop, PostgreSQL, pgAdmin 4  
**Not used today:** MySQL Workbench, Jupyter, Power BI, COVID CSV loads

---

## Purpose of Day 1

Day 1 is the workshop, not the analysis. Three things must exist before data is loaded:

1. A place to store code and versions — **GitHub**
2. A place to store tables — **PostgreSQL**
3. A written plan so the model is not invented twice — **docs**

| Part | Question it answers | Output |
|---|---|---|
| 1A GitHub | Where does the work live, and how are versions saved? | Public repository with commits |
| 1B PostgreSQL | Where will tables live, and how are they grouped? | Database `za_pulse` + four schemas |
| 1C Documentation | What does each piece mean before we build it? | Architecture, dictionary, source registry |

---

## Meanings

### Git and GitHub

| Word | Meaning |
|---|---|
| **Git** | Version tool on your PC. It snapshots files when you commit. |
| **GitHub** | Website that hosts those snapshots. |
| **Repository / repo** | The project folder Git is watching. Ours is `za-pulse-covid19-analytics`. |
| **Clone** | Download a full copy onto your PC, still linked to GitHub. |
| **Commit** | A named snapshot. Nothing goes online yet. |
| **Push** | Send local commits to GitHub. |
| **Fetch / Pull** | Bring down commits that are on GitHub but not on this PC. |
| **Branch (`main`)** | The line of history we work on for this solo project. |
| **README.md** | First page of the repo. Explains the project. |
| **LICENSE** | Legal permission to use *your* code. We chose MIT. |
| **.gitignore** | Files Git must not snapshot (secrets, junk, virtual environments). |
| **.gitkeep** | Dummy file so Git will store an empty folder. Git ignores empty folders. |

### PostgreSQL

| Word | Meaning |
|---|---|
| **PostgreSQL** | The database engine. Stores tables and answers SQL. |
| **pgAdmin 4** | Official app for PostgreSQL. Not MySQL Workbench. |
| **Database** | Named container. Ours is `za_pulse`. |
| **Schema** | Folder inside the database. We use `raw`, `stg`, `core`, `meta`. |
| **`public` schema** | Created by default. Leave it. Do not put project tables there. |
| **SQL** | Language used to create schemas, tables, and queries. |

---

## Day 1A — GitHub

### 1. Create the repository

Opened [github.com/new](https://github.com/new). Created a **public** repo named `za-pulse-covid19-analytics` under **ShadrackHero**.

- **Why public?** Portfolio work. Other people must open it without asking.
- **Why that name?** Lowercase + hyphens. States country, topic, and that it is analytics.
- Description set to: end-to-end COVID-19 analytics using Python notebooks, PostgreSQL, SQL, DAX and Power BI.

### 2. Add a licence

A licence is not something you already “own”. GitHub attaches a standard text file. We chose **MIT**.

- MIT lets others learn from your notebooks if they keep your copyright notice.
- MIT covers **your** code only.
- Official COVID CSVs stay **CC BY-SA 4.0** (DSFSI / University of Pretoria). We credit them in the README and source registry.

### 3. Add `.gitignore`

Skipped on the create form, added afterwards. That is allowed.

Without it, Jupyter checkpoints, Python cache folders, and later database passwords can be committed by accident.

### 4. Confirm Git on the PC

```
git version 2.48.1.windows.1
```

GitHub Desktop uses this same engine, with buttons instead of commands.

### 5. PowerShell, then GitHub Desktop

Two commands were pasted on one line (`mkdir` and `cd`). PowerShell rejected that. Lesson: one command, then Enter.

We switched to **GitHub Desktop** so changes appear as a file list. That is a valid professional workflow.

### 6. Local folder

Working copy: `Desktop\za-pulse-covid19-analytics`.

A `Projects` copy may exist from the first clone attempt. GitHub Desktop must point at **one** folder. We kept Desktop.

### 7. `notebooks` folder

Git does not store empty folders. `notebooks/.gitkeep` exists so the folder is on GitHub before any notebook is written.

Windows named it `.gitkeep.txt` because file extensions were hidden. Harmless. Rename later if you want.

### 8. Commit and push

Example message: `Day 1: add Python gitignore and notebooks folder`.

A sentence is better than “update”. History is how you tell the project story.

---

## Day 1B — PostgreSQL

### Why PostgreSQL

Better default for analytics than MySQL: real schemas, window functions (`LAG` for “today minus yesterday”), clean CSV load. PostgreSQL was already installed, so we stayed there.

**MySQL Workbench talks to MySQL Server.** PostgreSQL is a different engine. Matching app: **pgAdmin 4**.

### Steps

1. Confirm the Windows service `postgresql-x64-16` (or 17) is **Running**.
2. Connect in pgAdmin: host `localhost`, port `5432`, user `postgres`. That password is from the installer, not GitHub.
3. Create database `za_pulse` so this project is not mixed into the default `postgres` database.
4. On `za_pulse`, run:

```sql
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS meta;
```

`IF NOT EXISTS` means you can run it twice safely.

### What each schema means

| Schema | Meaning | Rule |
|---|---|---|
| `raw` | Landing zone. Exact copy of each source file. | Do not clean here. |
| `stg` | Staging. Unpivoted, dates typed, duplicates removed. | Wash bay. |
| `core` | Model used by notebooks and Power BI. | Dimensions and facts only. |
| `meta` | Sources, load times, handwritten notes. | Lineage. |

This split is why the project can later accept three insert methods: CSV bulk into `raw`, a notebook download into `raw`, and typed `INSERT` into `meta`.

---

## Day 1C — documentation

| File | Why it exists |
|---|---|
| `docs/architecture.md` | Map: sources → schemas → notebooks → Power BI → GitHub |
| `docs/data-dictionary.md` | Planned tables, columns, province codes |
| `docs/source-registry.md` | Every dataset, with URL or method |
| `sql/01_create_schemas.sql` | Same SQL as Day 1B, saved in Git so the database can be recreated |

GitHub Desktop warned about LF vs CRLF line endings. **Ignored.** Normal on Windows.

Commit: `Day 1: add schema SQL and project documentation` → Push origin.

---

## What GitHub stores vs what PostgreSQL stores

- GitHub: code, docs, screenshots. **Not** the database and **not** passwords.
- PostgreSQL: tables and rows.

Those are different systems on purpose.

---

## What we did not do on Day 1

- No COVID CSV loaded
- No dimension or fact tables (Day 2)
- No Jupyter notebook
- No Power BI
- No DAX

If data is loaded before schemas and docs exist, cleaning starts in the wrong place.

---

## Problems we hit

| What happened | What it means |
|---|---|
| `mkdir` and `cd` on one PowerShell line | The shell runs one instruction at a time |
| Licence and `.gitignore` skipped on create | Add them later; the form is optional |
| Desktop copy vs Projects copy | Point GitHub Desktop at one folder |
| `.gitkeep.txt` | Turn on File name extensions in Explorer |
| LF / CRLF warning | Ignore it on Windows |
| MySQL Workbench vs pgAdmin | The GUI must match the engine |

---

## Interview version of Day 1

“I created a public repo, chose MIT for my code and credited the CC BY-SA data source, grouped the warehouse into raw / staging / core / meta, and wrote the architecture down before loading a single CSV.”

---

## Next

Day 2 stays in pgAdmin: empty tables (`dim_province`, `dim_date`, source register, load log, raw landing tables). Still no plots and still no Power BI.
