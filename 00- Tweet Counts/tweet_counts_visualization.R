renv::init()

library(readr)
counts <- read_csv("Desktop/us_taliban/tweet_counts.csv")


options(scipen = 100)
#HOW MANY TWEETS WE WILL HAVE TO EXTRACT?
sum(counts$day_count)


counts <- counts[,-1]
library(ggplot2)

ggplot(data = counts, aes(x = start, y = day_count))+
  geom_line(color = "#00AFBB", size = 2)





### SUBSET VERSION (ZOOMED IN)
library(lubridate)
counts$month <- month(counts$start)
counts_subset <- subset (counts, month > 7 & month <10)


p <- ggplot(data = counts_subset, aes(x = start, y = day_count))+
  geom_line(color = "#00AFBB", size = 2)
jpeg(file="tweet_counts_subset.jpeg")
p + stat_smooth(
  color = "#FC4E07", fill = "#FC4E07",
  method = "loess"
)
dev.off()



# DETECT PEAKS IN THE SUBSET VERSION
library(ggpmisc)

ggplot(data = counts_subset, aes(x = start, y = day_count))+
  geom_line(color = "#00AFBB", size = 2)
jpeg(file="tweet_counts_subset.jpeg")
p + stat_smooth(
  color = "#FC4E07", fill = "#FC4E07",
  method = "loess"
)
dev.off()

jpeg(file="tweet_counts_subset_v2.jpeg")
ggplot(counts_subset, aes(x = start, y = day_count),as.numeric = FALSE) + 
  geom_line() + 
  stat_peaks(colour = "orangered4") +
  stat_peaks(geom = "text", colour = "orangered4", 
             vjust = -0.5, x.label.fmt = "%D")+
  theme(axis.title.x = element_blank())+
  ylab("Tweet Count")+
  ggtitle("Tweet Counts Change During the Withdrawal") 
dev.off()
 # ylim(-500, 7300)

renv::snpashot()
