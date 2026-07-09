Descripion:
My goal was simply to avoid having to go down to the shop floor every day to manually check CNC log files. I started by automating the log download with PowerShell. Once I had the data on my laptop, I realized I could process it as well. I began working with Excel, and as new requirements came up, I introduced Power Query, Power BI, and Python. Along the way, I also discovered that the CNC logging itself wasn't working the way it should, so I redesigned that too. In the end, it evolved into a fully automated system.

Bemutató: 
N
Csak annyit szerettem volna, hogy ne kelljen minden nap lemennem a gépekhez kézzel logokat nézni. Először csak automatizáltam a logok letöltését PowerShellben. Utána rájöttem, hogy ha már nálam vannak az adatok, akkor fel is lehet dolgozni őket. Elkezdtem Excellel dolgozni, amikor egyre több igény jött, Power Queryt, Power BI-t és Pythont is bevontam. Közben kiderült, hogy maga a CNC oldali logolás is fejleszthető, ezért azt is átírtam. Végül egy teljesen automatikus rendszer lett belőle.


# Tool-Analysis, Logging-Update, UI lag minimizing, LocalAI
CNC tool cost analysis pipeline

# CNC Tool Cost Analysis Pipeline

End-to-end data pipeline for CNC tool cost analysis.  
Automated data collection → cleaning → modelling → python cripts and visualization.

 ## Key Achievements
 
- **Excluded UI lag (~3s->0.2s)** 
- **Optimized logging logic** – tool registration happens after each tool call
  instead of start/end of main program only
  - Result: reduced operator data manipulation possibilities
- **~1 hour saved every 2 days** based on high tool change frequency

## Technologies Used

- **PowerShell** – automated log collection and file management
- **Excel Power Query (M)** – ETL pipeline
- **Power BI** – measurements, visualization and dashboards
- **Windows Task Scheduler** – full automation
- **Heidenhain Klartext** – CNC program files (.H, .A, .TAB, .txt)
- **GIT** – Version control 
- **Virtual environments** – (venv) + requirements.txt


## Pipeline Overview

## 1. Data Collection (PowerShell)
- Automatic download and extraction of CNC machine log files (ZIP)
- Organized into unified folder structure
- Runs daily without manual intervention

## 2. ETL – Power Query
  - Reading raw text log files
  - Parsing rows and columns
  - Setting data types
  - Filtering invalid data
  - Calculated fields (e.g. cutting ratio, datetime)
  - Two views:
  - **Operational** – last ~2000 rows for daily analysis
  - **Strategic** – full year for cost analysis

## 3. Data Model
  - Separate fact and aggregated tables
  - **Operational dataset** – current data (1 month)
  - **Annual dataset** – full year cost analysis

## 4. Visualization (Power BI)
  - KPI cards (tool cost, tool count, machine utilization)
  - Pareto chart / tool cost breakdown (donut, waterfall)
  - Monthly trend and cumulative YTD cost
  - Dynamic filtering (job, product)

## 5. Automation
  - Daily log download (night)
  - Morning data refresh + save
  - Zero manual intervention required

## 6. Version Control
  - Git – full history of pipeline development

## 7. Python Automation
  - `refresh_helper.py` – automated Excel refresh via win32com
  - `koltseg_szamolo.py` – tool cost calculator per setup
  - `config.py` – centralized path management, multi-machine compatible
  - Box cloud sync detection before refresh
  - Formatted Excel output with **openpyxl**
    
## 8. AI Integration (In Progress)

### Local LLM Setup
- **Ollama** – local LLM runtime, fully offline
- **Llama 3.1 8B** – open source language model running on local hardware
- Offline - Zero data privacy risk – no data leaves the machine
- No API costs, no cloud dependency

### Natural Language Query Interface
- Conversational querying of CNC production data in Hungarian
- Python + LlamaIndex framework for LLM orchestration
- "Python calculates, AI interprets" architecture:
  - Pandas handles all data aggregations
  - LLM receives pre-computed summaries + business context
  - Result: no hallucination on numeric data

### Context Engineering
- Custom business context layer describing:
  - Data structure and column semantics
  - Domain-specific rules (valid JOB numbers, known data quality issues)
  - Expected output format and language
- Prompt engineering for manufacturing domain

### RAG Pipeline – Lessons Learned
- **ChromaDB** – local vector database
- **LlamaIndex** – RAG orchestration
- **OllamaEmbedding** – local embedding model
- Goal: semantic search over full production history
- Enables: "Which tool caused the most downtime last quarter?"
  without predefined queries
⟱
- Tested on 78,449 rows → 900MB vector index
- Finding: RAG excels at semantic/contextual queries,
  not numerical aggregations
- Decision: hybrid architecture chosen
  → Python handles all aggregations (accurate, fast)
  → LLM interprets pre-computed results (no hallucination)
- Result: reliable answers without full dataset embedding

## Use Cases
  - Tool cost analysis per setup
  - Identifying problematic tools
  - Operator error detection
  - Performance improvement tracking
  - Cycle time improvement analysis
  - Operator utilization monitoring
  - Cutting ratio analysis (program efficiency)


## Architecture
CNC Machines → PowerShell (ZIP extract) → Folder structure →  Power Query ETL (M language) → Data Model: Fact + Aggregations → PowerBi: Dashboards, Python: Cost calc 

## Project Status
✅ Active – running in production environment

*  This repository contains selected modules and automation logic from an end-to-end CNC data pipeline project.
*  This project is a personal practice implementation. All data, structure, and identifiers are anonymized or mocked for demonstration purposes and do not represent any proprietary or sensitive information.

## Dashboard Screenshots

### User-facing folder structure design for non-technical stakeholders.
![Folder stucture](GITHUB_front_structure.png)

### Monthly and YTD Trend
![Monthly YTD](Monthly-and-ytd.png)
