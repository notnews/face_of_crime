.PHONY: restore analysis manuscript paper format lint test check ci-docker clean

restore:
	Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); renv::restore(prompt = FALSE)'

analysis:
	Rscript scripts/99_run_all.R

manuscript:
	cd ms && latexmk -pdf -interaction=nonstopmode -halt-on-error face_of_crime.tex

paper: analysis manuscript

format:
	Rscript -e 'styler::cache_deactivate(); styler::style_dir("R"); styler::style_dir("scripts"); styler::style_dir("tests")'

lint:
	Rscript -e 'l <- unlist(lapply(c("R", "scripts", "tests"), lintr::lint_dir), recursive = FALSE); print(l); quit(status = as.integer(length(l) > 0))'

test:
	Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'

check: paper lint test

ci-docker:
	docker run --rm --platform linux/amd64 -v "$(CURDIR):/project" -w /project \
		-v face_of_crime_renv_cache:/root/.cache/R/renv \
		-e RENV_CONFIG_REPOS_OVERRIDE=https://packagemanager.posit.co/cran/latest \
		rocker/verse:4.6.0 bash -c "tlmgr install latexmk appendix booktabs caption chngcntr bm fancyhdr lmodern multirow natbib rotating sectsty setspace subcaption && make restore check"

clean:
	cd ms && latexmk -C face_of_crime.tex
