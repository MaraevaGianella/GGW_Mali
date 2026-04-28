# =============================================================================
# GGW_analysis.R — Data preparation, ethnobotanical indices, FAMD, and
#                  regression for the Great Green Wall project (Mali)
#
# Authors : [Maraeva Gianella, Ilaria Panero]
# Date    : 2026
# License : MIT
#
# Description
# -----------
# This script covers the following steps, in order:
#   1.  Data import and recoding
#   2.  Participant summary statistics (age, gender, education, ethnicity, religion)
#   3.  FAMD (Factor Analysis of Mixed Data) for five livelihood capitals:
#       human, social, natural, physical, financial
#   4.  Ethnobotanical indices (UR, CI, FC, NU, RFC, RI, UV, CVe, FL, PPV)
#   5.  Composite knowledge index via Correspondence Analysis (COA)
#   6.  Stepwise and refined linear regression models
#
# Input files (place all under data/, or adjust paths below):
#   data/
#   ├── survey_matrix_raw.csv        : raw survey matrix (numeric codes)
#   ├── survey_matrix_recoded.csv    : recoded & aggregated survey matrix
#   ├── ethnicity_religion.csv       : ethnicity and religion per participant
#   ├── uses.csv                     : use-category code table
#   ├── plant_parts_code.csv         : plant-part code table
#   ├── species_codes.csv            : species code table
#   └── conservation_status.csv      : conservation-status code table
#
# Output directories (must exist before running):
#   FAMD/Human/   FAMD/Social/   FAMD/Natural/   FAMD/Physical/   FAMD/Financial/
#   Ethnobotany/Results/
#
# Participant IDs are anonymised codes (e.g. TINS01).
# The mapping between original and anonymised IDs is held privately and is
# not included in this repository.
#
# Package citations: see README.md or manuscript Methods for full references.
# =============================================================================


# =============================================================================
# 0. LOAD ALL PACKAGES
# =============================================================================

library(dplyr)        # data wrangling
library(tidyr)        # pivoting
library(stringr)      # string helpers
library(purrr)        # functional programming helpers
library(tibble)       # modern data frames
library(here)         # project-relative paths

library(openxlsx)     # read/write .xlsx

library(FactoMineR)   # FAMD
library(factoextra)   # FAMD visualisations
library(missMDA)      # imputation for FAMD (loaded for completeness)
library(patchwork)    # combine ggplots

library(ethnobotanyR) # ethnobotanical indices
library(ade4)         # Correspondence Analysis (COA)

library(car)          # VIF for multicollinearity checks

library(ggplot2)      # plotting
library(ggrepel)      # non-overlapping labels


# =============================================================================
# 1. DATA IMPORT AND RECODING
# =============================================================================

# --- 1.1  Raw survey matrix ---------------------------------------------------
dataset <- read.csv("data/survey_matrix_raw.csv",
                    header = TRUE, sep = ",", strip.white = TRUE)
which(is.na(dataset), arr.ind = TRUE)

# --- 1.2  Code tables ---------------------------------------------------------
uses <- read.csv("data/uses.csv",
                 header = TRUE, sep = ",", strip.white = TRUE)
names(uses)[2] <- "use"

parts <- read.csv("data/plant_parts_code.csv",
                  header = TRUE, sep = ",", strip.white = TRUE)
parts <- parts[-c(13, 14), ]   # remove placeholder rows

species <- read.csv("data/species_codes.csv",
                    header = TRUE, sep = ",", strip.white = TRUE)
# Updated with accepted names and cultivation status (July 2024)

cons_status <- read.csv("data/conservation_status.csv",
                        header = TRUE, sep = ",", strip.white = TRUE)

# --- 1.3  Ethnicity and religion ----------------------------------------------
# Join key is the anonymised participant ID
ethn_rel <- read.csv("data/ethnicity_religion.csv",
                     header = TRUE, sep = ",", strip.white = TRUE)

# --- 1.4  Recode numeric codes to meaningful labels ---------------------------
# Note: Q54-Q55 kept as original (1 = No, 2 = Yes, consistent with other Qs).
# Errors found in the original matrix were corrected prior to archiving;
# see manuscript Supplementary Materials for details.

ds <- dataset %>%
  dplyr::mutate(Q01 = as.character(recode(Q01, '1' = "Male", '2' = "Female"))) %>%
  dplyr::mutate(Q02 = as.character(recode(Q02, '1' = "20-35", '2' = "36-50",
                                          '3' = "51-65", '4' = ">65"))) %>%
  dplyr::mutate(Q03 = as.character(recode(Q03, '1' = "Never married", '2' = "Married",
                                          '3' = "Divorced", '4' = "Separated",
                                          "5" = "Widowed"))) %>%
  dplyr::mutate(across(c(Q05, Q06),
    ~ as.character(recode(.x, '1' = "Some", '2' = "1-2",
                          '3' = "3-4", '4' = ">4")))) %>%
  dplyr::mutate(Q07 = as.character(recode(Q07,
    '1' = "Never been to school", '2' = "Incomplete primary",
    '3' = "Complete primary",     '4' = "Incomplete secondary",
    "5" = "Complete secondary",   '6' = "Professional technical education",
    '7' = "Higher (university)",  '8' = "Koranic"))) %>%
  dplyr::mutate(across(c(Q08, Q09),
    ~ as.character(recode(.x, '3' = "All", '2' = "Some",
                          '1' = "None", '99' = "N/A")))) %>%
  dplyr::mutate(Q10 = as.character(recode(Q10,
    '1' = "All", '2' = "Some", '3' = "None"))) %>%
  dplyr::mutate(across(c(Q11, Q12),
    ~ as.character(recode(.x, '4' = "Never", '3' = "Rarely (1-2 times)",
                          '2' = "Sometimes (3-10 times)",
                          '1' = "Often (>10 times)")))) %>%
  dplyr::mutate(Q13 = as.character(recode(Q13, '2' = "Yes", '1' = "No"))) %>%
  dplyr::mutate(across(Q14_1:Q19,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(across(c(Q20, Q21),
    ~ as.character(recode(.x, '1' = "Men", '2' = "Women", '3' = "Both")))) %>%
  dplyr::mutate(across(Q22_1:Q24_11,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q25 = as.character(recode(Q25,
    '3' = "Good", '2' = "Regular", '1' = "Bad"))) %>%
  dplyr::mutate(across(Q26:Q27_9,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(across(Q28:Q30,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No", "99" = "N/A")))) %>%
  dplyr::mutate(Q31 = as.character(recode(Q31,
    '1' = "None", '2' = "1-2", '3' = "3-4", '4' = "5+"))) %>%
  dplyr::mutate(across(Q32_1:Q32_7,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(across(Q33:Q34,
    ~ as.character(recode(.x, '3' = "Yes, free of charge",
                          '2' = "Yes, monetary compensation", '1' = "No")))) %>%
  dplyr::mutate(across(Q35_1:Q35_9,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q36 = as.character(recode(Q36,
    '1' = "None", '2' = "1", '3' = "2", '4' = "3", '5' = "4+"))) %>%
  dplyr::mutate(Q37 = as.character(recode(Q37,
    '2' = "Yes", '1' = "No", "99" = "N/A"))) %>%
  dplyr::mutate(across(Q38:Q41,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No",
                          '98' = "Does not know")))) %>%
  dplyr::mutate(Q42 = as.character(recode(Q42,
    '1' = "Fields", '2' = "Cattle", "3" = "Fallow",
    '4' = "Agroforestry Systems", '5' = "Forests"))) %>%
  dplyr::mutate(across(Q43_1:Q46,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q47 = as.character(recode(Q47,
    '1' = "Strongly degraded", '2' = "Degraded", "3" = "Not degraded"))) %>%
  dplyr::mutate(across(Q48_1:Q48_13,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(across(Q49:Q50,
    ~ as.character(recode(.x, '3' = "Decrease", '2' = "Stable",
                          "1" = "Increase", '98' = "Does not know")))) %>%
  dplyr::mutate(across(Q51_1:Q51_8,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q52 = as.character(recode(Q52,
    '2' = "Yes", '1' = "No", '98' = "Does not know"))) %>%
  dplyr::mutate(across(Q54_1:Q58,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q59 = as.character(recode(Q59,
    '2' = "Yes", '1' = "No", "99" = "N/A"))) %>%
  dplyr::mutate(Q60 = as.character(recode(Q60,
    '1' = "1-2", '2' = "3-4", "3" = "5+"))) %>%
  dplyr::mutate(Q61 = as.character(recode(Q61,
    '3' = "Modern (metal roof, clay bricks or concrete)",
    '2' = "Mixed (modern and traditional)",
    "1" = "Traditional (straw roof, mud bricks)"))) %>%
  dplyr::mutate(across(Q62_1:Q63_14,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q64 = as.character(recode(Q64,
    '1' = "None", '2' = "1-2", '3' = "3-4", "4" = "5+"))) %>%
  dplyr::mutate(across(Q65:Q70,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q71 = as.character(recode(Q71,
    '1' = "None", '2' = "1", '3' = "2", "4" = "3+"))) %>%
  dplyr::mutate(Q72 = as.character(recode(Q72,
    '1'  = "Agriculture",   '2'  = "Cattle",
    '3'  = "Fishing",       "4"  = "Commerce",
    '5'  = "Arts and crafts",
    '6'  = "Manual trades (mason, carpenter, mechanic)",
    '7'  = "Salary (days of work with another farmer)",
    '8'  = "State work",    '9'  = "Inflow of money from abroad",
    '10' = "Traditional medicine",
    '11' = "Sale of planks and wood",
    '12' = "Sale of charcoal",
    '13' = "Gardening (growing vegetables)", '14' = "Other"))) %>%
  dplyr::mutate(Q73 = as.character(recode(Q73,
    '1'  = "Agriculture",   '2'  = "Cattle",
    '3'  = "Fishing",       "4"  = "Commerce",
    '5'  = "Arts and crafts",
    '6'  = "Manual trades (mason, carpenter, mechanic)",
    '7'  = "Salary (days of work with another farmer)",
    '8'  = "State work",    '9'  = "Inflow of money from abroad",
    '10' = "Traditional medicine",
    '11' = "Sale of planks and wood",
    '12' = "Sale of charcoal",
    '13' = "Gardening (growing vegetables)",
    '14' = "Other",         '99' = "N/A"))) %>%
  dplyr::mutate(Q74 = as.character(recode(Q74, '2' = "Yes", '1' = "No"))) %>%
  dplyr::mutate(Q75 = as.character(recode(Q75,
    '3' = "Increase", '2' = "Stable", '1' = "Decrease"))) %>%
  dplyr::mutate(across(Q76:Q80_4,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  dplyr::mutate(Q82 = as.character(recode(Q82,
    '2' = "Yes", '1' = "No", "99" = "N/A"))) %>%
  dplyr::mutate(across(Q83:Q86,
    ~ as.character(recode(.x, '2' = "Yes", '1' = "No")))) %>%
  # Replace numeric codes with text labels for plant variables
  dplyr::mutate(across(Species_code,
    ~ with(species, Plant.name[match(.x, Number)]))) %>%
  dplyr::mutate(across(used_part,
    ~ with(parts, Used_part[match(.x, Number)]))) %>%
  dplyr::mutate(across(conservation_status,
    ~ with(cons_status, Conservation_Status[match(.x, Number)]))) %>%
  dplyr::mutate(across(Use,
    ~ with(uses, use[match(.x, Number)])))

# --- 1.5  Add ethnicity / religion and deduplicate ---------------------------
# Join on anonymised participant ID; ethnicity_religion.csv also contains
# Village, which can be used for village-level summaries if needed.
ds <- left_join(ds, ethn_rel, by = "ID")

# One row per individual (long format has multiple rows per plant cited)
ds_filtered <- ds %>%
  distinct(ID, .keep_all = TRUE) %>%
  filter(if_all(everything(), ~ !str_detect(as.character(.), "error")))


# =============================================================================
# 2. PARTICIPANT SUMMARY STATISTICS
# =============================================================================

# Helper: frequency table with percentages
freq_table <- function(data, col) {
  col_name <- deparse(substitute(col))
  data %>%
    filter(!is.na({{ col }})) %>%
    group_by({{ col }}) %>%
    summarise(
      count      = n(),
      percentage = round(n() / sum(!is.na(data[[col_name]])) * 100, 1),
      .groups    = "drop"
    )
}

age_summary       <- freq_table(ds_filtered, Q02)
gender_summary    <- freq_table(ds_filtered, Q01)
education_summary <- freq_table(ds_filtered, Q07)
ethnic_summary    <- freq_table(ds_filtered, Ethnicity)
religion_summary  <- freq_table(ds_filtered, Religion)


# =============================================================================
# 3. FAMD — FACTOR ANALYSIS OF MIXED DATA
# =============================================================================
# Pipeline per capital:
#   (a) Subset columns  (b) chars -> factors, prepend col name to levels
#   (c) standardise numerics  (d) define active vs supplementary variables
#   (e) run FAMD  (f) select variables (contrib >= 100/p)
#   (g) export to Excel  (h) visualisations

# Helper: make factor levels unique by prepending the column name
make_levels_unique <- function(df) {
  result <- lapply(names(df), function(col_name) {
    x <- df[[col_name]]
    if (is.factor(x)) levels(x) <- paste(col_name, levels(x), sep = "_")
    x
  })
  as.data.frame(setNames(result, names(df)))
}

# Helper: run FAMD and return result tables
run_famd <- function(my_data_famd, K = 5,
                     sup_vars = c("Region", "Ethnicity", "Religion")) {
  sup_idx <- match(sup_vars, names(my_data_famd))
  res     <- FactoMineR::FAMD(my_data_famd, ncp = K, sup.var = sup_idx,
                              graph = FALSE)

  eig      <- as.data.frame(factoextra::get_eigenvalue(res))
  contrib  <- data.frame(variable = rownames(res$var$contrib),
                         res$var$contrib[, 1:K], row.names = NULL)
  cos2_tbl <- data.frame(variable = rownames(res$var$cos2),
                         res$var$cos2[, 1:K], row.names = NULL)
  coord    <- data.frame(variable = rownames(res$var$coord),
                         res$var$coord[, 1:K], row.names = NULL)

  contrib_mean <- 100 / nrow(res$var$contrib)

  selected <- contrib %>%
    tidyr::pivot_longer(-variable, names_to = "dimension",
                        values_to = "contrib") %>%
    left_join(
      cos2_tbl %>% tidyr::pivot_longer(-variable, names_to = "dimension",
                                       values_to = "cos2"),
      by = c("variable", "dimension")
    ) %>%
    filter(!is.na(contrib), !is.na(cos2), contrib >= contrib_mean) %>%
    group_by(variable) %>%
    summarise(
      dims_selected = paste(unique(dimension), collapse = ", "),
      max_contrib   = max(contrib, na.rm = TRUE),
      max_cos2      = max(cos2,    na.rm = TRUE),
      .groups       = "drop"
    ) %>%
    arrange(desc(max_contrib), desc(max_cos2))

  list(res = res, eig = eig, contrib = contrib, cos2 = cos2_tbl,
       coord = coord, selected = selected)
}

# Helper: export FAMD tables to Excel
save_famd_xlsx <- function(famd_list, filepath) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "eig.val")
  openxlsx::writeData(wb, "eig.val",  famd_list$eig,      rowNames = TRUE)
  openxlsx::addWorksheet(wb, "contrib")
  openxlsx::writeData(wb, "contrib",  famd_list$contrib,  rowNames = FALSE)
  openxlsx::addWorksheet(wb, "coord")
  openxlsx::writeData(wb, "coord",    famd_list$coord,    rowNames = FALSE)
  openxlsx::addWorksheet(wb, "cos2")
  openxlsx::writeData(wb, "cos2",     famd_list$cos2,     rowNames = FALSE)
  openxlsx::addWorksheet(wb, "selected")
  openxlsx::writeData(wb, "selected", famd_list$selected, rowNames = FALSE)
  openxlsx::saveWorkbook(wb, file = filepath, overwrite = TRUE)
}

# Helper: standard FAMD visualisations
plot_famd <- function(res.famd, K = 5) {
  fviz_screeplot(res.famd)
  plot_list <- list()
  k <- 1
  for (i in 1:(K - 1)) {
    for (j in (i + 1):K) {
      plot_list[[k]] <- fviz_famd_var(res.famd, axes = c(i, j), repel = TRUE) +
        ggtitle(paste("Dim", i, "vs Dim", j))
      k <- k + 1
    }
  }
  print(wrap_plots(plot_list, ncol = 2))
  fviz_contrib(res.famd, "var", axes = 1)
  fviz_contrib(res.famd, "var", axes = 2)
  fviz_famd_var(res.famd, repel = TRUE)
  fviz_famd_var(res.famd, "quanti.var", col.var = "contrib", repel = TRUE)
  fviz_famd_var(res.famd, "quali.var",  col.var = "contrib", repel = TRUE)
  fviz_mfa_ind(res.famd, geom = "point", repel = TRUE)
  fviz_mfa_ind(res.famd, geom = "point", habillage = "Region",
               addEllipses = TRUE, repel = TRUE)
  fviz_mfa_ind(res.famd, geom = "point", habillage = "Ethnicity",
               addEllipses = TRUE, repel = TRUE)
  fviz_mfa_ind(res.famd, geom = "point", habillage = "Religion",
               addEllipses = TRUE, repel = TRUE)
}

# Shared constants
sup_vars <- c("Region", "Ethnicity", "Religion")
id_vars  <- c("ID", "Year1", "Y2")
K        <- 5

# Helper: load recoded matrix, merge ethnicity/religion, deduplicate
load_famd_data <- function() {
  df   <- read.csv("data/survey_matrix_recoded.csv",
                   header = TRUE, sep = ",", strip.white = TRUE)
  ethn <- read.csv("data/ethnicity_religion.csv",
                   header = TRUE, sep = ",", strip.white = TRUE)
  left_join(df, ethn, by = "ID") %>%
    distinct(ID, .keep_all = TRUE) %>%
    filter(if_all(everything(), ~ !str_detect(as.character(.), "error")))
}


# --- 3.1  Human capital -------------------------------------------------------
df_filtered <- load_famd_data()
human       <- df_filtered[, c(1:31, 241, 242)]

human[sapply(human, is.character)] <-
  lapply(human[sapply(human, is.character)], as.factor)
human_recoded      <- make_levels_unique(human)
human_recoded[, 9] <- scale(human_recoded[, 9])

my_data           <- human_recoded
my_data[sup_vars] <- lapply(my_data[sup_vars], as.factor)
my_data_active    <- my_data[, !names(my_data) %in% c(id_vars, sup_vars)]
my_data_famd      <- cbind(my_data_active, my_data[sup_vars])

famd_human <- run_famd(my_data_famd, K)
save_famd_xlsx(famd_human, "./FAMD/Human/famd_human_ggw.xlsx")
plot_famd(famd_human$res, K)


# --- 3.2  Social capital ------------------------------------------------------
df_filtered <- load_famd_data()
social      <- df_filtered[, c(1:5, 32:40, 241, 242)]

social[sapply(social, is.character)] <-
  lapply(social[sapply(social, is.character)], as.factor)
social_recoded            <- make_levels_unique(social)
social_recoded[, c(3, 5)] <- scale(social_recoded[, c(3, 5)])

my_data           <- social_recoded
my_data[sup_vars] <- lapply(my_data[sup_vars], as.factor)
my_data_active    <- my_data[, !names(my_data) %in% c(id_vars, sup_vars)]
my_data_famd      <- cbind(my_data_active, my_data[sup_vars])

famd_social <- run_famd(my_data_famd, K)
save_famd_xlsx(famd_social, "./FAMD/Social/famd_social_ggw.xlsx")
plot_famd(famd_social$res, K)


# --- 3.3  Natural capital -----------------------------------------------------
df_filtered <- load_famd_data()
natural     <- df_filtered[, c(1:5, 41:60, 133, 206:209, 241, 242)]

sp_tbl  <- read.csv("data/species_codes.csv",
                    header = TRUE, sep = ",", strip.white = TRUE)[, 1:2]
sp_tbl  <- rbind(sp_tbl, data.frame(Number = 0, Plant.name = "No species"))
natural <- natural %>%
  mutate(Q54 = with(sp_tbl, Plant.name[match(Q54, Number)]),
         Q55 = with(sp_tbl, Plant.name[match(Q55, Number)]))

natural[, c(3, 5)] <- scale(natural[, c(3, 5)])
natural[sapply(natural, is.character)] <-
  lapply(natural[sapply(natural, is.character)], as.factor)
natural_recoded <- make_levels_unique(natural)

my_data           <- natural_recoded
my_data[sup_vars] <- lapply(my_data[sup_vars], as.factor)
my_data_active    <- my_data[, !names(my_data) %in% c(id_vars, sup_vars)]
my_data_famd      <- cbind(my_data_active, my_data[sup_vars])

famd_natural <- run_famd(my_data_famd, K)
save_famd_xlsx(famd_natural, "./FAMD/Natural/famd_natural_ggw.xlsx")
plot_famd(famd_natural$res, K)


# --- 3.4  Physical capital ----------------------------------------------------
df_filtered <- load_famd_data()
physical    <- df_filtered[, c(1:5, 210:221, 241, 242)]

physical[, c(3, 5)] <- scale(physical[, c(3, 5)])
physical[sapply(physical, is.character)] <-
  lapply(physical[sapply(physical, is.character)], as.factor)
physical_recoded <- make_levels_unique(physical)

my_data           <- physical_recoded
my_data[sup_vars] <- lapply(my_data[sup_vars], as.factor)
my_data_active    <- my_data[, !names(my_data) %in% c(id_vars, sup_vars)]
my_data_famd      <- cbind(my_data_active, my_data[sup_vars])

famd_physical <- run_famd(my_data_famd, K)
save_famd_xlsx(famd_physical, "./FAMD/Physical/famd_physical_ggw.xlsx")
plot_famd(famd_physical$res, K)


# --- 3.5  Financial capital ---------------------------------------------------
df_filtered <- load_famd_data()
financial   <- df_filtered[, c(1:5, 222:235, 241, 242)]

financial[, c(3, 5)] <- scale(financial[, c(3, 5)])
financial[sapply(financial, is.character)] <-
  lapply(financial[sapply(financial, is.character)], as.factor)
financial_recoded <- make_levels_unique(financial)

my_data           <- financial_recoded
my_data[sup_vars] <- lapply(my_data[sup_vars], as.factor)
my_data_active    <- my_data[, !names(my_data) %in% c(id_vars, sup_vars)]
my_data_famd      <- cbind(my_data_active, my_data[sup_vars])

famd_financial <- run_famd(my_data_famd, K)
save_famd_xlsx(famd_financial, "./FAMD/Financial/famd_financial_ggw.xlsx")
plot_famd(famd_financial$res, K)


# =============================================================================
# 4. ETHNOBOTANICAL INDICES
# =============================================================================

# Filter: non-cultivated species only (Cultivated_2015_Mali == 0)
data1 <- ds[, c(1, 385:388)] %>%
  left_join(species, by = c("Species_code" = "Plant.name")) %>%
  filter(Cultivated_2015_Mali != 1)

# Summary of most-cited species
top_species_data <- data1 %>%
  group_by(Taxon_name_accepted, Authors_accepted) %>%
  summarise(
    Citations = n(),
    Uses      = paste(unique(Use),       collapse = ", "),
    UsedParts = paste(unique(used_part), collapse = ", "),
    .groups   = "drop"
  ) %>%
  arrange(desc(Citations))

top_n_species       <- 3
top_species_summary <- head(top_species_data, top_n_species)
cat("Most commonly cited species:\n",
    paste(top_species_summary$Taxon_name_accepted,
          top_species_summary$Authors_accepted, collapse = "; "),
    "\nPrimary uses:", paste(top_species_summary$Uses,      collapse = ", "),
    "\nPlant parts:", paste(top_species_summary$UsedParts,  collapse = ", "), "\n")

# Abbreviate accepted names (first 2 letters of genus + dot + epithet)
data1 <- data1 %>%
  mutate(
    Taxon_name_truncated = sub("^(\\w{2})\\w* ", "\\1. ", Taxon_name_accepted),
    Species_code         = Taxon_name_truncated
  ) %>%
  select(1:5)

# Wide format: one column per use category (binary 0/1)
df_transformed <- data1 %>%
  mutate(value = 1) %>%
  pivot_wider(
    names_from  = Use, values_from = value, values_fill = 0,
    values_fn   = list(value = function(x) as.numeric(length(x) > 0))
  )

df1 <- df_transformed[, c(1, 2, 5:18)] %>%
  rename(informant = ID, sp_name = Species_code)

# Save input table (aids reproducibility checks)
write.csv(df1, "Ethnobotany/Results/input_ethnobotany.csv", row.names = FALSE)

# Deduplicate: one row per informant-species pair (needed for FC / RFC)
df1_binary <- df1 %>%
  group_by(informant, sp_name) %>%
  summarise(across(where(is.numeric), ~ as.integer(sum(.) > 0)),
            .groups = "drop")

# --- Compute indices ----------------------------------------------------------
URs  <- ethnobotanyR::URs(df1)          # Use Reports
URsum<- ethnobotanyR::URsum(df1)        # Sum of all Use Reports
CIs  <- ethnobotanyR::CIs(df1)          # Cultural Importance Index
FCs  <- ethnobotanyR::FCs(df1_binary)   # Frequency of Citation
NUs  <- ethnobotanyR::NUs(df1)          # Number of Uses
RFCs <- ethnobotanyR::RFCs(df1_binary)  # Relative Frequency of Citation
RI   <- ethnobotanyR::RIs(df1)          # Relative Importance Index
UV   <- ethnobotanyR::UVs(df1)          # Use Value
CVe  <- ethnobotanyR::CVe(df1)          # Cultural Value
FLs  <- ethnobotanyR::FLs(df1)          # Fidelity Level

# --- Plant Part Value index ---------------------------------------------------
totaluse_per_species <- data1 %>%
  group_by(Species_code) %>%
  summarise(total_uses = n(), .groups = "drop")

totaluse_per_species_part <- data1 %>%
  group_by(Species_code, used_part) %>%
  summarise(total_uses = n(), .groups = "drop")

PPV <- left_join(totaluse_per_species_part, totaluse_per_species,
                 by = "Species_code", suffix = c("_part", "_total")) %>%
  group_by(Species_code, used_part) %>%
  summarise(ppv = total_uses_part / total_uses_total, .groups = "drop") %>%
  rename(id_species = Species_code, part_used = used_part)

# --- Citation summary statistics ---------------------------------------------
cited_per_informant <- df1 %>%
  distinct(informant, sp_name) %>%
  group_by(informant) %>%
  summarise(n_species_cited = n(), .groups = "drop")

citation_summary <- tibble(
  Metric = c("Number of respondents", "Max species per respondent",
             "Min species per respondent", "Mean species per respondent",
             "Median species per respondent", "Total citations"),
  Value  = c(nrow(cited_per_informant),
             max(cited_per_informant$n_species_cited),
             min(cited_per_informant$n_species_cited),
             round(mean(cited_per_informant$n_species_cited), 2),
             median(cited_per_informant$n_species_cited),
             sum(cited_per_informant$n_species_cited))
)
print(citation_summary)

# Merged summary of all indices
summary_table <- URs %>%
  left_join(CIs,  by = "sp_name") %>%
  left_join(FCs,  by = "sp_name") %>%
  left_join(NUs,  by = "sp_name") %>%
  left_join(RFCs, by = "sp_name") %>%
  left_join(RI,   by = "sp_name") %>%
  left_join(UV,   by = "sp_name") %>%
  left_join(CVe,  by = "sp_name")

# --- Export to Excel ----------------------------------------------------------
wb_idx <- openxlsx::createWorkbook()
for (nm in c("URs", "CIs", "FCs", "NUs", "RFCs", "RI", "UV", "CVe", "FLs")) {
  openxlsx::addWorksheet(wb_idx, nm)
  openxlsx::writeData(wb_idx, nm, get(nm), rowNames = FALSE)
}
openxlsx::addWorksheet(wb_idx, "PPV")
openxlsx::writeData(wb_idx, "PPV", PPV, rowNames = FALSE)
openxlsx::addWorksheet(wb_idx, "summary_table")
openxlsx::writeData(wb_idx, "summary_table", summary_table, rowNames = FALSE)
openxlsx::saveWorkbook(wb_idx,
  "./Ethnobotany/Results/ethnobotany_indices.xlsx", overwrite = TRUE)

# --- Visualisations -----------------------------------------------------------
plot_index_bar <- function(df, x, y, y_lab, expand_add = c(0, 0.1)) {
  ggplot(df, aes(x = .data[[x]], y = .data[[y]], fill = .data[[x]])) +
    geom_bar(stat = "identity") +
    labs(x = "Species", y = y_lab) +
    theme_bw() +
    theme(legend.position = "none",
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
    scale_y_continuous(expand = expansion(add = expand_add))
}

plot_index_bar(URs,  "sp_name", "URs",  "Use Report (UR)",                     c(0, 10))
plot_index_bar(CIs,  "sp_name", "CI",   "Cultural Importance Index (CI)",       c(0, 0.1))
plot_index_bar(FCs,  "sp_name", "FCs",  "Frequency of Citation (FC)",           c(0, 10))
plot_index_bar(NUs,  "sp_name", "NUs",  "Number of Uses (NU)",                  c(0, 0.1))
plot_index_bar(RFCs, "sp_name", "RFCs", "Relative Frequency of Citation (RFC)", c(0, 0.1))
plot_index_bar(RI,   "sp_name", "RIs",  "Relative Importance Index (RI)",       c(0, 0.02))
plot_index_bar(UV,   "sp_name", "UV",   "Use Value (UV)",                       c(0, 0.2))
plot_index_bar(CVe,  "sp_name", "CVe",  "Cultural Value (CVe)",                 c(0, 0.05))

ggplot(FLs, aes(x = sp_name, y = FLs, fill = Primary.use)) +
  geom_bar(stat = "identity", position = "fill") +
  labs(x = "Species", y = "Fidelity Level (FL)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggplot(FLs, aes(x = sp_name, y = FLs, fill = Primary.use)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Species", y = "Fidelity Level (FL)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
  scale_y_continuous(expand = expansion(add = c(0, 5)))

ggplot(PPV, aes(x = id_species, y = ppv, fill = part_used)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(x = "Species", y = "Plant Part Use Value") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
  scale_y_continuous(expand = expansion(add = c(0, 0.02))) +
  scale_fill_viridis_d() +
  coord_flip()


# =============================================================================
# 5. COMPOSITE KNOWLEDGE INDEX VIA CORRESPONDENCE ANALYSIS (COA)
# =============================================================================

cols <- c("Species_code", "Use", "used_part")

ds1 <- ds[, c("ID", cols)] %>%
  left_join(species, by = c("Species_code" = "Plant.name")) %>%
  filter(Cultivated_2015_Mali != 1)

# Count unique species / uses / parts per informant
countdati <- ds1 %>%
  distinct() %>%
  group_by(ID) %>%
  summarise(across(all_of(cols), ~ length(unique(.))), .groups = "drop")

# Run COA
dd <- data.frame(countdati[, -1])
row.names(dd) <- countdati$ID

ca1 <- ade4::dudi.coa(dd, scannf = FALSE)
ade4::scatter(ca1, clab.row = 0.2)

cat("Cumulative variance explained:\n")
print(cumsum(ca1$eig) / sum(ca1$eig))

# Weighted composite index: each axis weighted by its eigenvalue proportion
IndexCA <- as.matrix(ca1$li) %*% as.vector(ca1$eig / sum(ca1$eig))
cat("IndexCA range:", min(IndexCA), "to", max(IndexCA), "\n")


# =============================================================================
# 6. REGRESSION MODELS
# =============================================================================

# Helper: extract coefficients/diagnostics and save to Excel
save_model_xlsx <- function(step_mod, ref_mod, filepath) {
  extract_model <- function(mod) {
    s      <- summary(mod)
    coeffs <- as.data.frame(s$coefficients)
    coeffs$Variable <- rownames(coeffs)
    diag   <- data.frame(
      Statistic = c("Residual SE", "R-squared",
                    "Adj R-squared", "F-statistic"),
      Value     = c(s$sigma, s$r.squared,
                    s$adj.r.squared, s$fstatistic[1])
    )
    list(coeffs = coeffs, diag = diag)
  }
  s1 <- extract_model(step_mod)
  s2 <- extract_model(ref_mod)
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Stepwise Coefficients")
  openxlsx::writeData(wb, "Stepwise Coefficients", s1$coeffs)
  openxlsx::addWorksheet(wb, "Stepwise Diagnostics")
  openxlsx::writeData(wb, "Stepwise Diagnostics",  s1$diag)
  openxlsx::addWorksheet(wb, "Refined Coefficients")
  openxlsx::writeData(wb, "Refined Coefficients",  s2$coeffs)
  openxlsx::addWorksheet(wb, "Refined Diagnostics")
  openxlsx::writeData(wb, "Refined Diagnostics",   s2$diag)
  openxlsx::saveWorkbook(wb, filepath, overwrite = TRUE)
}

# --- 6.1  Model using FAMD-selected variables ---------------------------------
df_filtered <- load_famd_data()
subset_df <- subset(df_filtered, select = c(
  "ID", "Q16", "Q23", "Q09", "Q11", "Q12", "Q08", "Q21", "Q33",
  "Ethnicity", "Q29", "Q30", "Q35", "Q48", "Q51", "Q41", "Q36",
  "Q54", "Q50", "Region", "Q60", "Q71", "Religion", "Q64", "Q63",
  "Q83", "Q84", "Q73", "Q75"
))

df_reg <- subset_df %>%
  distinct(ID, .keep_all = TRUE) %>%
  filter(if_all(everything(), ~ !str_detect(as.character(.), "error")))

df_reg$IndexCA <- IndexCA[match(df_reg$ID, countdati$ID)]

cat("IndexCA — Mean:",   round(mean(df_reg$IndexCA,   na.rm = TRUE), 3),
    " Median:", round(median(df_reg$IndexCA, na.rm = TRUE), 3),
    " SD:",     round(sd(df_reg$IndexCA,     na.rm = TRUE), 3),
    " Range:",  paste(round(range(df_reg$IndexCA, na.rm = TRUE), 3),
                      collapse = " - "), "\n")

ggplot(df_reg, aes(x = IndexCA)) +
  geom_histogram(binwidth = 0.1, color = "black", fill = "lightblue") +
  labs(title = "Distribution of IndexCA", x = "IndexCA", y = "Frequency") +
  theme_minimal()

df_model        <- df_reg[!is.na(df_reg$IndexCA), ]
predictor_names <- setdiff(names(df_model), c("ID", "IndexCA"))
full_formula    <- as.formula(paste("IndexCA ~",
                                    paste(predictor_names, collapse = " + ")))
null_model      <- lm(IndexCA ~ 1,      data = df_model)
full_model      <- lm(full_formula,     data = df_model)
stepwise_model  <- step(null_model,
                        scope     = list(lower = null_model, upper = full_model),
                        direction = "both")
summary(stepwise_model)

refined_formula <- as.formula("IndexCA ~ Q48 + Ethnicity + Q12 + Q60 + Q75")
refined_model   <- lm(refined_formula, data = df_model)
summary(refined_model)
par(mfrow = c(2, 2)); plot(refined_model); par(mfrow = c(1, 1))
car::vif(refined_model)

cat("AIC — Stepwise:", AIC(stepwise_model),
    "| Refined:", AIC(refined_model), "\n")

save_model_xlsx(stepwise_model, refined_model,
                "./Ethnobotany/Results/model_results_FAMD_vars.xlsx")


# --- 6.2  Full-variable model -------------------------------------------------
df_full         <- load_famd_data()
df_full$IndexCA <- IndexCA[match(df_full$ID, countdati$ID)]

df_full <- df_full %>%
  mutate(across(where(is.character), as.factor)) %>%
  mutate(across(where(is.factor), function(x) {
    if (all(grepl("^[0-9.]+$", levels(x)))) as.numeric(as.character(x)) else x
  }))

predictor_names_full <- setdiff(
  names(df_full),
  c("ID", "IndexCA", "species_Top10", "Species_code", "Use", "used_part",
    "conservation_status", "Year1", "Y2", "Q32", "Q62")
)
predictor_names_full <-
  predictor_names_full[!grepl("Q54|Q55", predictor_names_full)]

df_model_full   <- df_full[!is.na(df_full$IndexCA), ]
full_formula2   <- as.formula(paste("IndexCA ~",
                                    paste(predictor_names_full, collapse = " + ")))
null_model2     <- lm(IndexCA ~ 1,   data = df_model_full)
full_model2     <- lm(full_formula2, data = df_model_full)
stepwise_model2 <- step(null_model2,
                        scope     = list(lower = null_model2, upper = full_model2),
                        direction = "both")
summary(stepwise_model2)

refined_formula2 <- as.formula(
  "IndexCA ~ Ethnicity + Q38 + Q45 + Q60 + Q70 + Q15 + Q57 + Q59 + Q74 +
             Q51 + Q56 + Q84 + Q37 + Q47 + Q04 + Q03 + Q75 + Q69 + Q72 +
             Q79 + Q58"
)
refined_model2 <- lm(refined_formula2, data = df_model_full)
summary(refined_model2)
par(mfrow = c(2, 2)); plot(refined_model2); par(mfrow = c(1, 1))
car::vif(refined_model2)

save_model_xlsx(stepwise_model2, refined_model2,
                "./Ethnobotany/Results/model_results_all_vars.xlsx")
