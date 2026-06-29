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
    "lockfile is available, it falls back to r-packages.tsv metadata, then\n",
    "requirements.txt. GitHub/remotes packages and the recorded Bioconductor\n",
    "release are restored from the backup metadata when available.\n\n",
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
bioconductor_version_file <- file.path(backup_dir, "bioconductor-version.txt")

target_library <- Sys.getenv("R_RESTORE_LIBRARY", unset = .libPaths()[[1]])
dir.create(target_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(target_library, .libPaths())))

options(repos = c(CRAN = "https://cloud.r-project.org"))

has_value <- function(value) {
  length(value) > 0 &&
    !is.na(value[[1]]) &&
    nzchar(trimws(as.character(value[[1]])))
}

clean_value <- function(value) {
  if (!has_value(value)) {
    return("")
  }

  trimws(as.character(value[[1]]))
}

metadata_value <- function(row, field) {
  if (!field %in% names(row)) {
    return("")
  }

  clean_value(row[[field]])
}

empty_values <- function(values) {
  is.na(values) | !nzchar(trimws(as.character(values)))
}

read_first_line <- function(path) {
  if (!file.exists(path)) {
    return("")
  }

  lines <- readLines(path, warn = FALSE, n = 1)
  clean_value(lines)
}

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

bioconductor_version <- read_first_line(bioconductor_version_file)
if (has_value(bioconductor_version)) {
  options(renv.bioconductor.version = bioconductor_version)
}

installed_version <- function(package) {
  tryCatch(
    as.character(packageVersion(package)),
    error = function(error) NA_character_
  )
}

read_package_metadata <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  metadata <- read.delim(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  required_columns <- c("Package", "Version")
  missing_columns <- setdiff(required_columns, names(metadata))
  if (length(missing_columns) > 0) {
    warning(
      "Ignoring ",
      basename(path),
      "; missing column(s): ",
      paste(missing_columns, collapse = ", ")
    )
    return(NULL)
  }

  metadata
}

read_requirements <- function(path) {
  empty <- data.frame(
    Package = character(),
    Version = character(),
    stringsAsFactors = FALSE
  )

  if (!file.exists(path)) {
    return(empty)
  }

  lines <- trimws(readLines(path, warn = FALSE))
  lines <- lines[nzchar(lines)]
  lines <- lines[!grepl("^#", lines)]

  rows <- lapply(lines, function(line) {
    parts <- strsplit(line, "==", fixed = TRUE)[[1]]
    if (length(parts) != 2) {
      warning("Skipping malformed requirement: ", line)
      return(NULL)
    }

    data.frame(
      Package = parts[[1]],
      Version = parts[[2]],
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)

  if (length(rows) == 0) {
    return(empty)
  }

  do.call(rbind, rows)
}

external_metadata_rows <- function(metadata) {
  if (is.null(metadata)) {
    return(NULL)
  }

  if ("Priority" %in% names(metadata)) {
    external <- empty_values(metadata$Priority)
  } else {
    external <- rep(TRUE, nrow(metadata))
  }

  metadata[external & !empty_values(metadata$Package), , drop = FALSE]
}

append_missing_requirements <- function(metadata_rows, requirement_rows) {
  if (is.null(metadata_rows) || nrow(metadata_rows) == 0) {
    return(requirement_rows)
  }

  if (nrow(requirement_rows) == 0) {
    return(metadata_rows)
  }

  missing <- requirement_rows[
    !requirement_rows$Package %in% metadata_rows$Package,
    ,
    drop = FALSE
  ]
  if (nrow(missing) == 0) {
    return(metadata_rows)
  }

  for (column in setdiff(names(metadata_rows), names(missing))) {
    missing[[column]] <- NA_character_
  }
  for (column in setdiff(names(missing), names(metadata_rows))) {
    metadata_rows[[column]] <- NA_character_
  }

  rbind(metadata_rows, missing[names(metadata_rows)])
}

package_metadata <- read_package_metadata(packages_file)
requirement_rows <- read_requirements(requirements_file)
restore_rows <- append_missing_requirements(
  external_metadata_rows(package_metadata),
  requirement_rows
)
if (!is.null(restore_rows) && nrow(restore_rows) > 0) {
  restore_rows <- restore_rows[!duplicated(restore_rows$Package), , drop = FALSE]
}

remote_fields <- c(
  "RemoteType",
  "RemoteHost",
  "RemoteRepo",
  "RemoteUsername",
  "RemoteRef",
  "RemoteSha",
  "RemoteUrl",
  "RemoteSubdir",
  "RemotePkgRef"
)

package_origin <- function(row) {
  repository <- metadata_value(row, "Repository")
  remote_type <- tolower(metadata_value(row, "RemoteType"))

  if (
    identical(remote_type, "bioconductor") ||
      grepl("Bioconductor", repository, ignore.case = TRUE)
  ) {
    return("bioconductor")
  }

  if (
    has_value(remote_type) &&
      !remote_type %in% c("cran", "standard", "repository", "bioconductor")
  ) {
    return("remote")
  }

  "cran"
}

installed_remote_matches <- function(row) {
  package <- metadata_value(row, "Package")
  version <- metadata_value(row, "Version")
  if (!has_value(package) || !identical(installed_version(package), version)) {
    return(FALSE)
  }

  installed <- installed.packages(fields = remote_fields)
  if (!package %in% rownames(installed)) {
    return(FALSE)
  }

  installed_row <- installed[package, , drop = FALSE]
  for (field in remote_fields) {
    expected <- metadata_value(row, field)
    if (!has_value(expected)) {
      next
    }

    current <- metadata_value(installed_row, field)
    if (!identical(current, expected)) {
      return(FALSE)
    }
  }

  TRUE
}

remote_ref <- function(row, prefer_sha = TRUE) {
  if (prefer_sha && has_value(metadata_value(row, "RemoteSha"))) {
    return(metadata_value(row, "RemoteSha"))
  }

  if (has_value(metadata_value(row, "RemoteRef"))) {
    return(metadata_value(row, "RemoteRef"))
  }

  metadata_value(row, "RemoteSha")
}

remote_repo_slug <- function(row) {
  username <- metadata_value(row, "RemoteUsername")
  repo <- metadata_value(row, "RemoteRepo")
  if (has_value(username) && has_value(repo)) {
    return(paste(username, repo, sep = "/"))
  }

  pkg_ref <- metadata_value(row, "RemotePkgRef")
  if (has_value(pkg_ref)) {
    return(sub("@.*$", "", pkg_ref))
  }

  ""
}

install_remote_package <- function(row) {
  package <- metadata_value(row, "Package")
  remote_type <- tolower(metadata_value(row, "RemoteType"))
  ref <- remote_ref(row)
  subdir <- metadata_value(row, "RemoteSubdir")
  host <- metadata_value(row, "RemoteHost")
  url <- metadata_value(row, "RemoteUrl")
  slug <- remote_repo_slug(row)

  if (installed_remote_matches(row)) {
    message("Already installed from recorded remote: ", package)
    return(TRUE)
  }

  if (!install_if_missing("remotes")) {
    stop("Package remotes is required to restore remote packages.")
  }

  message("Installing remote package: ", package, " (", remote_type, ")")
  install_args <- list(upgrade = "never")
  if (has_value(ref)) {
    install_args$ref <- ref
  }
  if (has_value(subdir)) {
    install_args$subdir <- subdir
  }

  tryCatch(
    {
      if (identical(remote_type, "github")) {
        if (!has_value(slug)) {
          warning("Missing GitHub owner/repo metadata for package: ", package)
          return(FALSE)
        }

        install_args$repo <- slug
        if (has_value(host)) {
          install_args$host <- host
        }
        do.call(remotes::install_github, install_args)
      } else if (identical(remote_type, "gitlab")) {
        if (!has_value(slug)) {
          warning("Missing GitLab owner/repo metadata for package: ", package)
          return(FALSE)
        }

        install_args$repo <- slug
        if (has_value(host)) {
          install_args$host <- host
        }
        do.call(remotes::install_gitlab, install_args)
      } else if (identical(remote_type, "bitbucket")) {
        if (!has_value(slug)) {
          warning("Missing Bitbucket owner/repo metadata for package: ", package)
          return(FALSE)
        }

        install_args$repo <- slug
        do.call(remotes::install_bitbucket, install_args)
      } else if (remote_type %in% c("git", "xgit", "git2r")) {
        if (!has_value(url)) {
          warning("Missing git URL metadata for package: ", package)
          return(FALSE)
        }

        git_args <- list(url = url, upgrade = "never")
        if (has_value(ref)) {
          git_args$ref <- ref
        }
        if (has_value(subdir)) {
          git_args$subdir <- subdir
        }
        do.call(remotes::install_git, git_args)
      } else if (identical(remote_type, "url")) {
        if (!has_value(url)) {
          warning("Missing URL metadata for package: ", package)
          return(FALSE)
        }

        url_args <- list(url = url, upgrade = "never")
        if (has_value(subdir)) {
          url_args$subdir <- subdir
        }
        do.call(remotes::install_url, url_args)
      } else {
        warning("Unsupported remote type for package ", package, ": ", remote_type)
        return(FALSE)
      }
    },
    error = function(error) {
      stop(
        "Remote install failed for ",
        package,
        ": ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )

  TRUE
}

bioconductor_prepared <- FALSE
ensure_bioconductor <- function() {
  if (bioconductor_prepared) {
    return(TRUE)
  }

  if (!install_if_missing("BiocManager")) {
    stop("Package BiocManager is required to restore Bioconductor packages.")
  }

  if (has_value(bioconductor_version)) {
    message("Using recorded Bioconductor release: ", bioconductor_version)
    tryCatch(
      BiocManager::install(
        version = bioconductor_version,
        ask = FALSE,
        update = FALSE
      ),
      error = function(error) {
        warning(
          "Unable to activate recorded Bioconductor release ",
          bioconductor_version,
          ": ",
          conditionMessage(error)
        )
      }
    )
  }

  bioconductor_prepared <<- TRUE
  TRUE
}

install_bioconductor_package <- function(row) {
  package <- metadata_value(row, "Package")
  version <- metadata_value(row, "Version")
  current_version <- installed_version(package)

  if (!is.na(current_version) && identical(current_version, version)) {
    message("Already installed: ", package, " ", version)
    return(TRUE)
  }

  ensure_bioconductor()

  message("Installing Bioconductor package: ", package)
  install_args <- list(
    pkgs = package,
    ask = FALSE,
    update = FALSE
  )
  if (has_value(bioconductor_version)) {
    install_args$version <- bioconductor_version
  }

  do.call(BiocManager::install, install_args)
  TRUE
}

install_cran_package <- function(row) {
  package <- metadata_value(row, "Package")
  version <- metadata_value(row, "Version")
  current_version <- installed_version(package)

  if (!is.na(current_version) && identical(current_version, version)) {
    message("Already installed: ", package, " ", version)
    return(TRUE)
  }

  if (!install_if_missing("remotes")) {
    stop("Package remotes is required for CRAN version restore.")
  }

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

  TRUE
}

restore_from_rows <- function(rows, include_plain_cran = TRUE) {
  if (is.null(rows) || nrow(rows) == 0) {
    return(invisible(FALSE))
  }

  for (index in seq_len(nrow(rows))) {
    row <- rows[index, , drop = FALSE]
    origin <- package_origin(row)

    if (identical(origin, "remote")) {
      restored <- install_remote_package(row)
      if (!restored && include_plain_cran) {
        install_cran_package(row)
      }
    } else if (identical(origin, "bioconductor")) {
      install_bioconductor_package(row)
    } else if (include_plain_cran) {
      install_cran_package(row)
    }
  }

  invisible(TRUE)
}

if (file.exists(lockfile) && install_if_missing("renv")) {
  renv::restore(
    lockfile = lockfile,
    library = target_library,
    prompt = FALSE
  )
  restore_from_rows(restore_rows, include_plain_cran = FALSE)
  message("R environment restored from: ", normalizePath(lockfile))
  quit(status = 0)
}

if ((is.null(restore_rows) || nrow(restore_rows) == 0)) {
  stop(
    "Missing restore input. Expected renv.lock, r-packages.tsv, or requirements.txt under: ",
    backup_dir
  )
}

restore_from_rows(restore_rows)

message("R package restore completed into: ", normalizePath(target_library))
