# SOURCE: https://twarc-project.readthedocs.io/en/latest/twarc2_en_us/

# TWARC2 METHOD.

#where am I?
pwd
cd Desktop/us_taliban

#configure deyip bearer token'i girmek lazim.
twarc2 configure

## count check first
twarc2 searches --archive --start-time 2021-05-01 --end-time 2021-11-18 --counts-only query.txt tweet_counts.csv