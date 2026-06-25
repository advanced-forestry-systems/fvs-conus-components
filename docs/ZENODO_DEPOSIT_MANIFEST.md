# Zenodo deposit manifest: CONUS component equations

**Status:** staged, not deposited. Mint the DOI at manuscript submission, not before.
**Prepared:** 2026-06-21
**Workflow:** reuse the existing `~/zenodo_tools` / `zpub.py` pipeline on Cardinal (sign-in via
the standard request header, per the `zenodo-deposit` skill). Companion README and data
dictionary via the `data-curator` skill.

## Why stage now

The fitting inputs and objects below live only on Cardinal (home and scratch). Scratch is
auto-purged after about 90 days of no access. Home is near its 500G cap. This manifest fixes
the deposit contents so the archive can be assembled in one pass when the paper is ready, and
flags the scratch items to touch or relocate before then.

## Deposit contents (proposed single record, versioned)

| File (Cardinal path) | Size | Role |
|---|---|---|
| `~/fvs-conus/data/conus_remeasurement_pairs_metric_cond_v2.rds` | 448M | Master FIA remeasurement pairs (8.2M rows): the fitting and benchmark input for every component. |
| `~/fvs-conus/data/VAR_SDIMAX.csv` | 20K | FVS variant species-weighted maximum SDI (the baseline being replaced). |
| `~/fvs-conus/data/brms_SDImax.csv` | 11M | FIA-derived localized maximum SDI per plot (173,740 rows). |
| `~/fvs-conus/output/conus/dg_kue/v8/dg_kuehne_v8_100k_prod_residuals.rds` | 72M | Production diameter-growth residuals (Kuehne v8). |
| `~/fvs-conus/output/evaluation/ingrowth_master_table.csv` | 2.4K | Ingrowth count model evaluation summary. |
| `/fs/scratch/.../fvs-conus_output_conus/stand_level/topheight_gada_fit.rds` | <1K | Stand-level top-height GADA fit object. |
| `/fs/scratch/.../fvs-conus_output_conus/stand_level/topheight_gada_v2_fit.rds` | <1K | Top-height GADA v2 (CSPI asymptote). |
| `/fs/scratch/.../fvs-conus_output_conus/stand_level/ne_bench*_plots.csv`, `ne_bench_trees.csv` | ~95K | NE benchmark export (plot and tree level). |

Total raw is about 530M, well within a standard Zenodo record. Compress the two large `.rds`
before upload.

## Pre-deposit checklist

1. Touch the scratch `stand_level/` objects (or copy to home) so the purge clock resets while
   the manuscript is in progress.
2. Add a README and data dictionary (column definitions for the remeasurement pairs and the two
   SDImax tables) via `data-curator`.
3. Cross-link: cite the existing TreeMap max-SDI surface deposit (10.5281/zenodo.19509367) and
   the `cspi-conus` site-index deposit as the upstream inputs.
4. Backfill the minted DOI into the manuscript and into `holoros/fvs-conus-components` README.

## Not for Zenodo

The 100G `~/fvs-conus/output/` variant-run tree is regenerable from this repo plus the inputs
above; do not archive it. Code is preserved in `holoros/fvs-conus-components`, not Zenodo.

## Decision 2026-06-22: do NOT mint yet; staged, ready to execute at manuscript submission

Per the zenodo-deposit skill, deposit at submission and backfill the publication DOI as a metadata
update afterward. Minting now is premature: the DG residuals, stand-level fit objects, and ingrowth
tables will change when the FIX 2 ingrowth swap and the engine integration land, which would force a
v2. The big inputs (remeasurement pairs, SDImax tables) are also on home/scratch and not at
purge risk in the near term, so there is no urgency to deposit early.

### Execution recipe (when the manuscript is ready)
Upload host: Cardinal (files exceed 5 GB collectively; use tmux). Staging root:
/users/PUOM0008/crsfaaron/zenodo_staging/fvs-conus-components/zenodo_upload/. Token: ~/.zenodo_token
(mode 600, already on Cardinal). Use the skill's scripts/upload_to_zenodo.py.

1. Build zenodo_upload/ (README + data_dictionary via data-curator; CITATION.cff; zenodo_metadata.json).
2. zenodo_metadata.json defaults for Aaron: upload_type=dataset; creators ORCID 0000-0003-2534-4478,
   affiliation "University of Maine, Center for Research on Sustainable Forests"; license cc-by-4.0;
   community forestry; access_right open; language eng; version 1.0.0. OMIT related_identifiers until
   the publication DOI exists (placeholder DOIs 400-fail).
3. files_to_upload.txt = absolute Cardinal paths from the table above (pairs, VAR_SDIMAX, brms_SDImax,
   dg residuals, ingrowth tables, stand-level fit objects, plus the final fitted-equation summaries).
4. tmux; module load python/3.11; pip install --user requests; python upload_to_zenodo.py
   --token-file ~/.zenodo_token --metadata zenodo_metadata.json --files-list files_to_upload.txt
   (add --sandbox for a dry run first; add --publish to mint).
5. Backfill the minted DOI into the manuscript Data/Code Availability, CITATION.cff, and the repo,
   then run update_metadata.py to add the publication DOI once the journal accepts.

Related deposits to cross-link: the TreeMap max-SDI surface (10.5281/zenodo.19509367) and the
cspi-conus site-index deposit (upstream inputs).
