library(testthat)
test_that('R version check works', {
  expect_no_error(check_r_version())
})
test_that('Directory structure is created', {
  expect_true(dir.exists('R'))
  expect_true(dir.exists('inst/shiny'))
  expect_true(dir.exists('data'))
})

