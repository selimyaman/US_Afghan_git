# Data Cleaning (Basics)

This process is just after location extraction and before the botometer predictions.

Here, we do: 
- re-compile the csv files that we got from twarc2
- import dataset into R
- merge the main dataset with the locations
- remove unnecassary locations
- remove accounts who follow less than 5 people or more than 1500 people.

etc.

Final product after running this R script is a cleaned version of the tweet dataset: `pre_bot_rep_v3.csv`
