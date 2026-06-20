#!/usr/bin/env Rscript
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Restore R packages from a backup created by r-freeze.R.
# Usage:
#   utility/r-restore.R [BACKUP_DIR]

args <- commandArgs(trailingOnly = TRUE)

show_help <- function() {
  cat(
    "Usage:\n",
    "  utility/r-restore.R [BACKUP_DIR]\n\n",
    "Restore R packages from BACKUP_DIR created by utility/r-freeze.R.\n\n",
    "The script prefers renv.lock for reproducible package restoration. If no\n",
    "lockfile is available, it falls back to requirements.txt and installs the\n",
    "listed packages into the active R library.\n\n",
    "Environment:\n",
    "  R_RESTORE_LIBRARY  Target R library. Defaults to .libPaths()[1].\n\n",
    "Arguments:\n",
    "  BACKUP_DIR         Backup directory. Defaults to r-env-backup.\n",
    sep = ""
  )
}

if (length(args) > 0 && args[[1]] %in% c("-h", "--help")) {
  show_help()
  quit(status = 0)
}

backup_dir <- if (length(args) >= 1) args[[1]] else "r-env-backup"
lockfile <- file.path(backup_dir, "renv.lock")
requirements_file <- file.path(backup_dir, "requirements.txt")
packages_file <- file.path(backup_dir, "r-packages.tsv")

target_library <- Sys.getenv("R_RESTORE_LIBRARY", unset = .libPaths()[[1]])
dir.create(target_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(target_library, .libPaths())))

options(repos = c(CRAN = "https://cloud.r-project.org"))

install_if_missing <- function(package) {
  if (requireNamespace(package, quietly = TRUE)) {
    return(TRUE)
  }

  message("Installing missing package: ", package)
  tryCatch(
    {
      install.packages(package)
      requireNamespace(package, quietly = TRUE)
    },
    error = function(error) {
      warning("Unable to install ", package, ": ", conditionMessage(error))
      FALSE
    }
  )
}

installed_version <- function(package) {
  tryCatch(
    as.character(packageVersion(package)),
    error = function(error) NA_character_
  )
}

if (file.exists(lockfile) && install_if_missing("renv")) {
  renv::restore(
    lockfile = lockfile,
    library = target_library,
    prompt = FALSE
  )
  message("R environment restored from: ", normalizePath(lockfile))
  quit(status = 0)
}

if (!file.exists(requirements_file)) {
  stop(
    "Missing restore input. Expected renv.lock or requirements.txt under: ",
    backup_dir
  )
}

if (!install_if_missing("remotes")) {
  stop("Package remotes is required for requirements.txt fallback restore.")
}

package_metadata <- NULL
if (file.exists(packages_file)) {
  package_metadata <- read.delim(
    packages_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

package_repository <- function(package) {
  if (is.null(package_metadata) || !"Repository" %in% names(package_metadata)) {
    return("")
  }

  match_index <- match(package, package_metadata$Package)
  if (is.na(match_index)) {
    return("")
  }

  package_metadata$Repository[[match_index]]
}

requirements <- trimws(readLines(requirements_file, warn = FALSE))
requirements <- requirements[nzchar(requirements)]
requirements <- requirements[!grepl("^#", requirements)]

for (line in requirements) {
  parts <- strsplit(line, "==", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    warning("Skipping malformed requirement: ", line)
    next
  }

  package <- parts[[1]]
  version <- parts[[2]]
  current_version <- installed_version(package)

  if (!is.na(current_version) && identical(current_version, version)) {
    message("Already installed: ", package, " ", version)
    next
  }

  repository <- package_repository(package)
  if (grepl("Bioconductor", repository, ignore.case = TRUE)) {
    if (!install_if_missing("BiocManager")) {
      stop("Package BiocManager is required to restore Bioconductor packages.")
    }

    message("Installing Bioconductor package: ", package)
    BiocManager::install(package, ask = FALSE, update = FALSE)
  } else {
    message("Installing CRAN package: ", package, "==", version)
    tryCatch(
      remotes::install_version(
        package,
        version = version,
        repos = getOption("repos"),
        upgrade = "never"
      ),
      error = function(error) {
        warning(
          "Exact version install failed for ",
          package,
          ": ",
          conditionMessage(error),
          ". Installing current repository version instead."
        )
        install.packages(package)
      }
    )
  }
}

message("R package restore completed into: ", normalizePath(target_library))
