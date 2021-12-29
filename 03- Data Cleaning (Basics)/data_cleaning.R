# DATA CLEANING (BASICS)
library(readr)
library(dplyr)

# GET REPRESENTATIVE DATASET (59K)
# 15 gun araliklarla json formatinda cektim twarc2'yi kullanarak. 
  #sonra csv'e dönüştürdüm. her bir csv dosyasını çekip, burada birleştirmek gerekiyor.
setwd("~/Desktop/us_taliban/raw_rep_sample")
file_names = list.files(pattern="*.csv")
mydata <- do.call(rbind,lapply(file_names,read.csv))
write.csv(mydata,"tweets_sample_v2(representative).csv", row.names = FALSE)

# get the tweet data
tweets <- read_csv("tweets_sample_v2(representative).csv")
set.seed(123)
options(scipen = 100)

#after running location_extraction.py file in the previous section, we now have location info.
#let's import that.
location <- read_csv("location.csv")

#merge the dataset with location info
test <- cbind(tweets, location)

# see how many unique authors we have in a 60k tweet set:
(J <- length(unique(test$author.id)))

# now, remove those who say they're NOT from the US
#test <- subset(test, Country=="Unknown" | Country=="United States")
test <- subset(test, Country=="United States" | geo.country=="United States")
test <- subset(test, geo.country=="United States" | is.na(geo.country)==TRUE)

# remove non-english tweets. our focus in on the US.
test <- subset(test, lang == "en")

#remove unnecessary variables (from 74 variables to 50)
test <- test %>% select(c(
  -entities.cashtags,
  -entities.urls,
  -entities.mentions,
  -entities.hashtags,
  -author.entities.description.cashtags,
  -author.entities.description.hashtags,
  -author.entities.description.mentions,
  -author.entities.description.urls,
  -author.entities.url.urls,
  -lang,
  -context_annotations,
  -entities.annotations,
  -attachments.media,
  -attachments.media_keys,
  -attachments.poll.duration_minutes,
  -attachments.poll.end_datetime,
  -attachments.poll.id,
  -attachments.poll.options,
  -attachments.poll.voting_status,
  -attachments.poll_ids,
  -author.profile_image_url,
  -author.pinned_tweet_id,
  -author.url,
  -author.protected,
  -X__twarc.retrieved_at,
  -X__twarc.url,
  -X__twarc.version,
  -X))
  #-"...74",
  #this has to be false anyway
  #-"__twarc.url")
  

# see how many NAs we have
sapply(test, function(x) sum(is.na(x)))


# remove those accounts who follow less than 5 accounts or more than 2000 accounts.
# bu ikinci kisimda justification: people can't really follow that much of people. the more people you follow, the more meaningless the signals.
# hatta bununla ilgili bir calisma var midir acaba
test2 <- subset(test, test$author.public_metrics.following_count >5 & 
              test$author.public_metrics.following_count <1500)

# see how many of them are now gone
(nrow(test)-nrow(test2))/nrow(test) # 30 %! Great.

# get back to test
test <- test2

# how many unique authors we have now?
(J2<-length(unique(test$author.id)))
(J-J2)/J # GOOD, REDUCTION OF USERS BY 81%
write_csv2(test2, "pre_bot_rep_v3.csv")


# eger text'in uzunlugu 20 karakterden kisaysa datasetten cikar
bakalim <- subset(test, nchar(text) >20)