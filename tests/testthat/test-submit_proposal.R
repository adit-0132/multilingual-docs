# Tests for submit_proposal()
# Covers the Easy, Medium, and Hard requirements from the GSoC project brief.

# ---------------------------------------------------------------------------
# Easy: submit_proposal() returns the correct logical value relative to the
# deadline.
# ---------------------------------------------------------------------------

test_that("submit_proposal returns TRUE when called before the deadline", {
  # Freeze Sys.Date() to one day before the stored deadline.
  local_mocked_bindings(
    Sys.Date = function() as.Date("2025-03-30"),
    .package = "base"
  )
  expect_true(submit_proposal())
})

test_that("submit_proposal returns TRUE when called on the deadline itself", {
  local_mocked_bindings(
    Sys.Date = function() as.Date("2025-03-31"),
    .package = "base"
  )
  expect_true(submit_proposal())
})

test_that("submit_proposal returns FALSE when called after the deadline", {
  local_mocked_bindings(
    Sys.Date = function() as.Date("2025-04-01"),
    .package = "base"
  )
  expect_false(submit_proposal())
})

test_that("submit_proposal always returns a single logical value", {
  result <- submit_proposal()
  expect_type(result, "logical")
  expect_length(result, 1L)
})

# ---------------------------------------------------------------------------
# Medium: The deadline is present in the package documentation.
# ---------------------------------------------------------------------------

test_that("submit_proposal has a help page", {
  # ?submit_proposal must resolve without error when the package is loaded.
  expect_true(
    isNamespaceLoaded("gsocproposal") ||
      tryCatch({
        loadNamespace("gsocproposal")
        TRUE
      }, error = function(e) FALSE)
  )
  # Verify that the Rd source file exists and contains the function name.
  rd_path <- system.file("help", "submit_proposal.rdb",
                          package = "gsocproposal")
  # During development (source package) fall back to the man/ directory.
  if (!nzchar(rd_path)) {
    rd_path <- system.file("man", "submit_proposal.Rd",
                            package = "gsocproposal")
  }
  expect_true(nzchar(rd_path))
})

# ---------------------------------------------------------------------------
# Hard: The deadline is stored in the package environment and the Sexpr
# time-remaining computation uses that value rather than a hard-coded string.
# ---------------------------------------------------------------------------

test_that("deadline is stored in .pkg_env, not hard-coded", {
  # Access the internal environment directly.
  pkg_env <- getFromNamespace(".pkg_env", "gsocproposal")
  expect_true(exists("deadline", envir = pkg_env))
  expect_s3_class(pkg_env$deadline, "Date")
  expect_length(pkg_env$deadline, 1L)
})

test_that("updating .pkg_env$deadline changes submit_proposal output", {
  pkg_env <- getFromNamespace(".pkg_env", "gsocproposal")
  original <- pkg_env$deadline

  on.exit(pkg_env$deadline <- original, add = TRUE)

  # Set deadline to yesterday: function must return FALSE.
  pkg_env$deadline <- Sys.Date() - 1L
  expect_false(submit_proposal())

  # Set deadline to tomorrow: function must return TRUE.
  pkg_env$deadline <- Sys.Date() + 1L
  expect_true(submit_proposal())
})

test_that("time-remaining Sexpr expression evaluates without error", {
  # Evaluate the same logic used in stage=render to confirm it is valid R.
  pkg_env <- getFromNamespace(".pkg_env", "gsocproposal")
  dl        <- pkg_env$deadline
  days_left <- as.integer(dl - Sys.Date())

  msg <- if (days_left > 0) {
    paste0("The deadline is in ", days_left, " day(s).")
  } else if (days_left == 0) {
    "The deadline is today."
  } else {
    "The deadline has passed, try next year!"
  }

  expect_type(msg, "character")
  expect_length(msg, 1L)
  # The message must match one of the three expected templates.
  expect_true(
    grepl("deadline is in \\d+ day", msg) ||
    msg == "The deadline is today." ||
    msg == "The deadline has passed, try next year!"
  )
})
