# Data Dictionary

All files are UTF-8 encoded, comma-separated, with a header row.

---

## village_coordinates.csv

Geographic coordinates of the 23 interview villages, with dominant ethnicity.
This file contains no individual-level data.

| Column    | Type   | Description |
|-----------|--------|-------------|
| Village   | string | Village name |
| Ethnicity | string | Dominant ethnicity of the village (`Dogon`, `Sarakolé`, `Maure`) |
| Latitude  | float  | Latitude in decimal degrees (WGS84) |
| Longitude | float  | Longitude in decimal degrees (WGS84) |

**Notes:**
- 23 villages across two regions: Kayes (Sarakolé and Maure villages) and
  Mopti (Dogon villages).
- Coordinates were recorded with a GPS device in the field and converted from
  DMS to decimal degrees.

---

## ethnicity_religion.csv

Ethnicity and religion per participant (one row per participant, 152 total).
Participant IDs are anonymised codes — see README for details.

| Column    | Type   | Description |
|-----------|--------|-------------|
| ID        | string | Anonymised participant ID (e.g. `TINS01`). Join key to survey matrices. |
| Village   | string | Village of the participant |
| Ethnicity | string | Ethnic group: `Dogon`, `Sarakolé`, or `Maure` |
| Religion  | string | Religion: `Musulmane` or `Chrétienne` |

---

## Lookup / code tables

These four files decode numeric codes in the survey matrices. They contain
no participant data and can be shared openly.

---

## uses.csv

Lookup table mapping numeric codes to plant use categories.

| Column | Type    | Description |
|--------|---------|-------------|
| Number | integer | Numeric code used in the survey matrix (column `Use`) |
| Use    | string  | Use category label |

**Use categories (14 total):**

| Code | Label       | Description |
|------|-------------|-------------|
| 1    | HumanFood   | Plant used as food for humans |
| 2    | AnimalFood  | Plant used as food or fodder for animals |
| 3    | HumanHealth | Plant used in traditional medicine for humans |
| 4    | AnimalHealth| Plant used in traditional medicine for animals |
| 5    | Sculpture   | Plant used for carving or sculpture |
| 6    | Fertilizer  | Plant used as fertilizer or soil amendment |
| 7    | Wood        | Plant used for firewood or fuel |
| 8    | Lumber      | Plant used for construction timber |
| 9    | Artisanal   | Plant used for craft production |
| 10   | Beekeeping  | Plant used in beekeeping |
| 11   | Dyeing      | Plant used as a natural dye |
| 12   | Shade       | Plant used for shade provision |
| 13   | Coal        | Plant used for charcoal production |
| 14   | Essence     | Plant used for essential oils or perfume |

---

## plant_parts_code.csv

Lookup table mapping numeric codes to plant part categories.

| Column    | Type    | Description |
|-----------|---------|-------------|
| Number    | integer | Numeric code used in the survey matrix (column `used_part`) |
| Used_part | string  | Plant part label |

**Plant parts (12 total):**

| Code | Label    |
|------|----------|
| 1    | Leaves   |
| 2    | Fruits   |
| 3    | Flowers  |
| 4    | Bark     |
| 5    | Roots    |
| 6    | Pulp     |
| 7    | Trunk    |
| 8    | Sap      |
| 9    | Gum      |
| 10   | Tuber    |
| 11   | Branches |
| 12   | Apple    |

---

## conservation_status.csv

Lookup table mapping numeric codes to locally perceived conservation status,
as reported by interview participants.

| Column              | Type    | Description |
|---------------------|---------|-------------|
| Number              | integer | Numeric code used in the survey matrix (column `conservation_status`) |
| Conservation_Status | string  | Perceived conservation status label |

| Code | Label       | Description |
|------|-------------|-------------|
| 1    | Abundant    | Species perceived as locally abundant |
| 2    | Threatened  | Species perceived as locally declining or threatened |
| 3    | Rare        | Species perceived as locally rare |
| 4    | Disappeared | Species perceived as locally extinct or disappeared |

---

## species_codes.csv

Reference table of plant species recorded in the survey, with taxonomic
reconciliation against the IPNI (International Plant Names Index) and
cultivation/origin status.

| Column                | Type    | Description |
|-----------------------|---------|-------------|
| Number                | integer | Numeric code used in the survey matrix (column `Species_code`) |
| Plant name            | string  | Name as recorded in the field (may be a synonym, spelling error, or common name) |
| Status                | string  | Taxonomic status of the field name: `Accepted`, `Synonym`, `Spelling error`, or `Common name` |
| Taxon_name_accepted   | string  | Accepted taxon name per IPNI |
| Authors_accepted      | string  | Authorship of the accepted name |
| IPNI_accepted         | string  | IPNI identifier of the accepted name |
| Binomial_clean_accepted | string | Clean binomial (genus + epithet) of the accepted name; `NA` for genus-level entries |
| Origine               | string  | Origin category of the species (see below) |
| Cultivated_2015_Mali  | integer | Whether the species is cultivated in Mali (2015 data): `1` = yes, `0` = no |
| Codes_Origine         | integer | Numeric code for Origine: `1` = Locale, `2` = Exotic |

**Origine categories:**

| Value              | Description |
|--------------------|-------------|
| Locale             | Native or naturalised species |
| Exotique fruitière | Exotic fruit-producing species |
| Exotique bois      | Exotic timber species |
| Exotique potagère  | Exotic vegetable/garden species |
| Exotique tubercule | Exotic root/tuber crop species |

**Notes:**
- Species 73–85 are crop/vegetable species recorded by common name in the field;
  some are identified only to genus level (`Binomial_clean_accepted` = NA).
- Taxonomic reconciliation was carried out in July 2024 using IPNI
  (https://www.ipni.org).
- The `Cultivated_2015_Mali` flag is used in the analysis to filter out
  cultivated species from ethnobotanical indices (only non-cultivated
  species are included in UR, CI, RFC, etc.).
