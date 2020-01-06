#!/bin/bash

USER=
PASS=

mysql -u $USER -p$PASS -e "call output_dim_date();" camdram_dw > output/dim_date.tsv
mysql -u $USER -p$PASS -e "call output_dim_society();" camdram_dw > output/dim_society.tsv
mysql -u $USER -p$PASS -e "call output_dim_society_combo();" camdram_dw > output/output_dim_society_combo.tsv
mysql -u $USER -p$PASS -e "call output_dim_story();" camdram_dw > output/dim_story.tsv
mysql -u $USER -p$PASS -e "call output_dim_time();" camdram_dw > output/dim_time.tsv
mysql -u $USER -p$PASS -e "call output_dim_venue();" camdram_dw > output/dim_venue.tsv
mysql -u $USER -p$PASS -e "call output_fct_performances();" camdram_dw > output/fct_performances.tsv
