# GGW — Ethnobotany and Livelihoods in the Great Green Wall (Mali)

## Overview

This repository contains the R code and input data used for analysis in:

> Ceci, P., Gianella, M., Panero, I., Burton, G. P., Sidibé, 
S. I., Sanogo, S., Kelly, B. A., Attorre, F., Ulian, T., 2026. 
Traditional knowledge and use of wild plant species in Mali: 
Correlations with households’ livelihood assets. *[Journal]*. DOI: [xxx]

The analysis covers:
1. Recoding of the raw survey matrix
2. Participant summary statistics
3. Factor Analysis of Mixed Data (FAMD) for five livelihood capitals
4. Ethnobotanical indices (UR, CI, FC, NU, RFC, RI, UV, CVe, FL, PPV)
5. Composite ethnobotanical knowledge index via Correspondence Analysis (COA)
6. Stepwise and refined linear regression models

---

## Repository structure

```
.
├── GGW_analysis.R               # Main analysis script
├── README.md                    # This file
├── DATA_DICTIONARY.md           # Column descriptions for all data files
│
├── data/                        # Input data files
│   ├── survey_matrix_raw.csv        : raw survey matrix (numeric codes)
│   ├── survey_matrix_recoded.csv    : recoded & aggregated survey matrix
│   ├── ethnicity_religion.csv       : ethnicity and religion per participant
│   ├── uses.csv                     : use-category code table
│   ├── plant_parts_code.csv         : plant-part code table
│   ├── species_codes.csv            : species code table
│   └── conservation_status.csv      : conservation-status code table
│
├── FAMD/                        # FAMD outputs (created by script)
│   ├── Human/
│   ├── Social/
│   ├── Natural/
│   ├── Physical/
│   └── Financial/
│
└── Ethnobotany/Results/         # Ethnobotanical index and model outputs
```

---

## Anonymisation

Participant IDs in all data files are anonymised codes (e.g. `TINS01`,
`BANK03`). The code prefix identifies the village; the number identifies the
individual within that village. The mapping between original field identifiers
and anonymised codes is held privately by the authors and is not included in
this repository. The `Community_ID` field (which contained interviewer names)
has been removed from both survey matrices.

---

## Data availability

The code tables (`uses.csv`, `plant_parts_code.csv`, `species_codes.csv`,
`conservation_status.csv`, `ethnicity_religion.csv`) contain no directly
identifying information and are shared openly.

The survey matrices (`survey_matrix_raw.csv`, `survey_matrix_recoded.csv`)
contain individual-level survey responses. Participant IDs are anonymised
(see above). These files are shared in this repository subject to the
conditions of the original ethics approval. If you have any concerns, please
contact the corresponding author.

---

## Requirements

R ≥ 4.2.0. Install all dependencies with:

```r
install.packages(c(
  "dplyr", "tidyr", "stringr", "purrr", "tibble", "here",
  "openxlsx",
  "FactoMineR", "factoextra", "missMDA", "patchwork",
  "ethnobotanyR", "ade4",
  "car",
  "ggplot2", "ggrepel"
))
```

Before running the script, create the output directories:

```r
dirs <- c("FAMD/Human", "FAMD/Social", "FAMD/Natural",
          "FAMD/Physical", "FAMD/Financial", "Ethnobotany/Results")
lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE)
```

---

## R package citations

| Package | Reference |
|---------|-----------|
| **dplyr**, **tidyr**, **stringr**, **purrr**, **tibble** | Wickham H, et al. (2019). Welcome to the tidyverse. *Journal of Open Source Software*, 4(43), 1686. https://doi.org/10.21105/joss.01686 |
| **here** | Müller K (2020). *here: A Simpler Way to Find Your Files*. R package v1.0.1. https://CRAN.R-project.org/package=here |
| **openxlsx** | Schauberger P, Walker A (2023). *openxlsx: Read, Write and Edit xlsx Files*. https://CRAN.R-project.org/package=openxlsx |
| **FactoMineR** | Lê S, Josse J, Husson F (2008). FactoMineR: An R Package for Multivariate Analysis. *Journal of Statistical Software*, 25(1), 1–18. https://doi.org/10.18637/jss.v025.i01 |
| **factoextra** | Kassambara A, Mundt F (2020). *factoextra: Extract and Visualize the Results of Multivariate Data Analyses*. https://CRAN.R-project.org/package=factoextra |
| **missMDA** | Josse J, Husson F (2016). missMDA: A Package for Handling Missing Values in Multivariate Data Analysis. *Journal of Statistical Software*, 70(1), 1–31. https://doi.org/10.18637/jss.v070.i01 |
| **patchwork** | Pedersen TL (2024). *patchwork: The Composer of Plots*. https://CRAN.R-project.org/package=patchwork |
| **ethnobotanyR** | Cámara-Leret R, et al. (2019). ethnobotanyR: Calculate Quantitative Ethnobotany Indices. https://CRAN.R-project.org/package=ethnobotanyR |
| **ade4** | Dray S, Dufour AB (2007). The ade4 package: Implementing the duality diagram for ecologists. *Journal of Statistical Software*, 22(4), 1–20. https://doi.org/10.18637/jss.v022.i04 |
| **car** | Fox J, Weisberg S (2019). *An R Companion to Applied Regression*, 3rd ed. Sage. https://socialsciences.mcmaster.ca/jfox/Books/Companion/ |
| **ggplot2** | Wickham H (2016). *ggplot2: Elegant Graphics for Data Analysis*. Springer-Verlag. https://ggplot2.tidyverse.org |
| **ggrepel** | Slowikowski K (2024). *ggrepel: Automatically Position Non-Overlapping Text Labels*. https://CRAN.R-project.org/package=ggrepel |

---

## License

Code: MIT License (see LICENSE file)
Data: Creative Commons Attribution 4.0 International (CC BY 4.0)
