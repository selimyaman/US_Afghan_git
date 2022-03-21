# STM

library(readr)
library(dplyr)
library(stm)
library(lubridate)
library(tidyr)
library(tictoc)
set.seed(123)
options(scipen=100)
tw<- read_csv("Data/post_ideo_bot.csv")

tw$month <- month(tw$created_at)

tw <- tw %>% separate(geo.full_name, c('place', 'state'),sep=",")

#remove infinite values
tw$ideal_point <- ifelse(is.infinite(tw$ideal_point)==TRUE, NA,
                         tw$ideal_point)

#remove bot accounts
test <- subset(tw, bot_detection=="user")

test <- tw %>%  slice_sample(n=1000)

test <- test %>% select( text,
                         author_id,
                         starts_with("public_metrics"),
                         starts_with("author.public_metrics"),
                         author.verified,
                         source,
                         month,
                         ideal_point,
                         state) 

test <- na.omit(test)

#export to run on HPC
#write.csv(test,"Data/pre_STM.csv")




words_to_be_removed <- c("afghanistan","kabul","taliban","amp","afghan","get","like", "taliban","Islamic Emirate","pashtun",
                         "pashto","kandahar","pashtuns","Ashraf Ghani")

#make lowercase, remove stopwords & numbers & punctuation, stem
processed <- textProcessor(test$text, 
                           metadata = test,
                           customstopwords = words_to_be_removed,
                           sparselevel = 0.99,
                           striphtml = TRUE)

out <- prepDocuments(processed$documents, 
                     processed$vocab, 
                     processed$meta,
                     lower.thresh = 0.05 * length(processed$documents),
                     upper.thresh = 0.95 * length(processed$documents))

docs <- out$documents
vocab <- out$vocab
meta <-out$meta



tic()
First_STM <- stm(documents = out$documents, vocab = out$vocab,
                 K = 10, prevalence = ~ author_id + 
                 s(month) + 
                 state +
                 s(author.public_metrics.followers_count)+
                 s(author.public_metrics.tweet_count)+
                 s(ideal_point),
                 max.em.its = 75, data = out$meta,
                 init.type = "Spectral", verbose = FALSE)
toc() # for 1000 tweets, took 94 secs. # for 82510, it would take 2.15 hours. 


saveRDS(First_STM, "STM_results/First_STM.Rds")
#z <- readRDS("STM_results/First_STM.Rds") # to read

## OK, NEITHER SELECTMODEL NOR FINDINGK. "MANYTOPICS" COMBINES THEM! I WILL USE THAT.

# see stm_manytopics.R for how to implement in HPC

# manytopics combines them, but do not allow parallel computing. So for that, I used stmprinter::many_models
# see stmrpinter.R

k <- seq(4,81, by=3)




# find the context for a given topic
findThoughts(First_STM, texts = meta$text,
             n = 2, topics = c(6,1))

#optimal number of topics

k <- seq(10,50, by=2)

tic()
findingk <- searchK(out$documents, out$vocab, K = k,
                    prevalence = ~ author_id + 
                      s(month) + 
                      state +
                      s(author.public_metrics.followers_count)+
                      s(author.public_metrics.tweet_count)+
                      s(ideal_point), 
                    data = meta, 
                    verbose=FALSE,
                    core=1)
toc()
#took 2 mins for 1k tweets
#save(findingk, "findingk.Rda)
load("findingk.Rda")


# So here is the process.:
# I run searchK function, trying many different number of topics.
# This is done in HPC (Zorro of AU) - see stm_hpc.R
# Now let's load the final result to investigate:
findingk <- readRDS("Data/findingk.RDS")
plot(findingk)
# visually inspect the plot.. \
# maximize held-out likelihood, minimize residuals, optimize semantic coherence..
# so a good number of topics seems to be 36.
# good plotting here: https://juliasilge.com/blog/evaluating-stm/
# now that we've chosen the number of topics, let's select the best model with k=36




# Once I found the optimal number of topics - 36 -, I run selectModel function. (stm_selectmodel.R)
stmSelect <- selectModel(     out$documents, 
                              out$vocab, 
                              K = 36,
                              prevalence = ~ author_id + 
                                s(month) + 
                                state +
                                s(author.public_metrics.followers_count)+
                                s(author.public_metrics.tweet_count)+
                                s(ideal_point), 
                              max.em.its = 75,
                              data = out$meta, 
                              runs = 30, 
                              seed = 123)

readRDS(stmSelect,"Data/stmSelect.RDS")


saveRDS(stmSelect,"stmSelect.RDS")



plotModels(stmSelect)




plot(findingk)

saveRDS(findingk,"Data\findingk.RDS")
z <- readRDS("Data\findingk.RDS")

predict_topics<-estimateEffect(formula = 1:10 ~ author.public_metrics.followers_count + s(month), 
                               stmobj = First_STM, 
                               metadata = out$meta, 
                               uncertainty = "Global")

plot(predict_topics, covariate = "author.public_metrics.followers_count", 
     topics = c(3, 5, 9,1,4),
     model = First_STM, method = "continuous", # for categorical, "difference"
     #cov.value1 = "Liberal", cov.value2 = "Conservative",
     xlab = "Follower Count",
     main = "Effect of Follower Count on Topics",
     #xlim = c(-.1, .1), 
     labeltype = "custom",
     ci.level = 0.95, #defaul 0.95
     nsims = 100, #default 100
     custom.labels = c('Topic 3', 'Topic 5','Topic 9','Topic 1', 'Topic 4'))
    #source: https://sicss.io/2020/materials/day3-text-analysis/topic-modeling/rmarkdown/Topic_Modeling.html#topic-models-for-short-text
    #see ?plot.EstimateEffect


# topic change over time
# passed

# interactive visualization
library(LDAvis)
library(servr)
toLDAvis(mod = First_STM,
         docs = out$documents)

library(stm, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.1")
library(readr, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.1")
library(stmprinter, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.1")



set.seed(123)
options(scipen=100)

test <- read_csv("pre_STM.csv")

test <- test[,-1]

words_to_be_removed <- c("afghanistan","kabul","taliban","amp","afghan","get","like", "taliban","Islamic Emirate","pashtun",
                       "pashto","kandahar","pashtuns","Ashraf Ghani")

processed <- textProcessor(test$text, 
                           metadata = test,
                           customstopwords = words_to_be_removed,
                           striphtml = TRUE)

out <- prepDocuments(processed$documents, 
                     processed$vocab, 
                     processed$meta,
                     lower.thresh = 0.01 * length(processed$documents),
                     upper.thresh = 0.99 * length(processed$documents))

docs <- out$documents
vocab <- out$vocab
meta <-out$meta

k <- seq(4,75, by=3)

print(parallel::detectCores())

ncore <- round(parallel::detectCores() * 0.8)
print(ncore)

stm_models <- many_models(
  K = k,
  documents = out$documents,
  vocab= out$vocab,
  prevalence = ~ author_id + 
    s(month) + 
    state +
    s(author.public_metrics.followers_count)+
    s(author.public_metrics.tweet_count)+
    s(ideal_point), 
  data = out$meta,
  cores = ncore,
  N = 5,
  runs = 15
)


saveRDS(stm_models,"stmprinter.RDS")



# MODEL SELECTION ---------------------------------------------------------



stats <- stmprinter::get_stats(stmprinter)
(length(unique(stats$n_topics))) # 24 topics tried...
(range(unique(stats$n_topics))) # ... from 4 to 73
#20 runs realied for each number of topics.

#write.csv(stats, "Data/stm_stats.csv")


stats <- read_csv("Data/stm_stats.csv")
stats <- stats[,-1]

sm <- stats %>% 
  group_by(n_topics) %>% 
  dplyr::summarise(semcoh=mean(semcoh),excl=mean(exc))

semcoh <- sm %>% ggplot(aes(x=n_topics,y=semcoh))+
  geom_line()+
  theme(axis.title.x = element_blank())+
  scale_x_continuous(breaks = seq(4,75, by=3))

exc <- sm %>% ggplot(aes(x=n_topics,y=excl))+
  geom_line()+
  scale_x_continuous(breaks = seq(4,75, by=3))



# we need a tradeoff between semantic coherence and exclusivity.
# 8-9-10 seem to be OK

# Compare the plot above with findingk plot:
findingk <- readRDS("~/Desktop/us-afghan-v2/Data/findingk.RDS")
plot(findingk)

findk_v2 <- readRDS("Data/findk_v2.RDS")
plot(findk_v2)
# What do we 


# let's say 10 is a good number for topic modeling.
# now question is: which run is the best? This is, if we don't use the spectral initialization (which is recommended by the stm's developers)
a <-stats_k10 %>% 
  group_by(run) %>% 
  summarise(excl = mean(exc)) 

b <- stats_k10 %>% 
  group_by(run) %>% 
  summarise(semcoh = mean(semcoh))

c <- full_join(a,b)     

ggplot (data=c, aes(x=run))+
  theme_classic() +
  geom_point(
    mapping=aes(y=excl, colour=excl),
    shape=3,
    size=10)+
  geom_point(
    mapping=aes(y=semcoh, colour=semcoh),
    shape=1,
    size=8)
# seems like any model run is quite similar to each other. so let's randomly select one of them.
set.seed(123)
r <- sample(seq(1,5),1)
k10 <- stmprinter$k10
deneme <- list(
  runout=k10$runout[[r]],
  semcoh=k10$semcoh[[r]],
  exclusivity=k10$exclusivity[[r]],
  sparsity=k10$sparsity[[r]]
)







library(stm, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")
library(readr, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")

set.seed(123)
options(scipen=100)

test <- read_csv("pre_STM.csv")

test <- test[,-1]

words_to_be_removed <- c("afghanistan","kabul","taliban","amp","afghan","get","like", "taliban","Islamic Emirate","pashtun",
                         "pashto","kandahar","pashtuns","Ashraf Ghani")

processed <- textProcessor(test$text, 
                           metadata = test,
                           customstopwords = words_to_be_removed,
                           striphtml = TRUE)

out <- prepDocuments(processed$documents, 
                     processed$vocab, 
                     processed$meta,
                     lower.thresh = 0.01 * length(processed$documents),
                     upper.thresh = 0.99 * length(processed$documents))

docs <- out$documents
vocab <- out$vocab
meta <-out$meta

#k <- seq(10,70, by=2)

stmSelect <- selectModel(     out$documents, 
                              out$vocab, 
                              K = 40,
                              prevalence = ~ author_id + 
                                 s(month) + 
                                 state +
                                 s(author.public_metrics.followers_count)+
                                 s(author.public_metrics.tweet_count)+
                                 s(ideal_point), 
                              max.em.its = 75,
                              data = out$meta, 
                              runs = 30, 
                              seed = 123)


saveRDS(stmSelect,"stmSelect.RDS")




library(stm, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")
library(readr, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")

set.seed(123)
options(scipen=100)

test <- read_csv("Data/pre_STM.csv")

test <- test[,-1]

words_to_be_removed <- c("afghanistan","kabul","taliban","amp","afghan","get","like", "taliban","Islamic Emirate","pashtun",
                         "pashto","kandahar","pashtuns","Ashraf Ghani")

processed <- textProcessor(test$text, 
                           metadata = test,
                           customstopwords = words_to_be_removed,
                           striphtml = TRUE)

out <- prepDocuments(processed$documents, 
                     processed$vocab, 
                     processed$meta,
                     lower.thresh = 0.01 * length(processed$documents),
                     upper.thresh = 0.99 * length(processed$documents))

docs <- out$documents
vocab <- out$vocab
meta <-out$meta

k <- seq(4,81, by=3)

manytopics <- manyTopics(     out$documents, 
                              out$vocab, 
                              K = k,
                              prevalence = ~ author_id + 
                                s(month) + 
                                state +
                                s(author.public_metrics.followers_count)+
                                s(author.public_metrics.tweet_count)+
                                s(ideal_point), 
                              max.em.its = 75,
                              data = out$meta, 
                              runs = 20, 
                              seed = 123)


saveRDS(manytopics,"manytopics.RDS")



#library("readr", lib.loc="/home/sy6876a/R-packages")

library(stm, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")
library(readr, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.0")

set.seed(123)
options(scipen=100)

test <- read_csv("pre_STM.csv")

test <- test[,-1]

words_to_be_removed <- c("afghanistan","kabul","taliban","amp","afghan","get","like", "taliban","Islamic Emirate","pashtun",
                         "pashto","kandahar","pashtuns","Ashraf Ghani")

processed <- textProcessor(test$text, 
                           metadata = test,
                           customstopwords = words_to_be_removed,
                           striphtml = TRUE)

out <- prepDocuments(processed$documents, 
                     processed$vocab, 
                     processed$meta,
                     lower.thresh = 0.01 * length(processed$documents),
                     upper.thresh = 0.99 * length(processed$documents))

docs <- out$documents
vocab <- out$vocab
meta <-out$meta

k <- seq(10,50, by=2)

findingk <- searchK(out$documents, out$vocab, K = k,
                    prevalence = ~ author_id + 
                      s(month) + 
                      state +
                      s(author.public_metrics.followers_count)+
                      s(author.public_metrics.tweet_count)+
                      s(ideal_point), 
                    data = meta, 
                    verbose=FALSE,
                    core=10)




saveRDS(findingk,"findingk.RDS")



# run a model with 16 topics. after long inspections, that number seems to be optimal.

library(stm, lib.loc = "/home/sy6876a/R/x86_64-pc-linux-gnu-library/4.1")

set.seed(123)
options(scipen=100)

out <- readRDS("pre_k16.RDS")

docs <- out$documents
vocab <- out$vocab
meta <-out$meta

k16 <- stm(out$documents, out$vocab, 
           K = 16,
           prevalence = ~ author_id + 
             s(month) + 
             state +
             s(author.public_metrics.followers_count)+
             s(author.public_metrics.tweet_count)+
             s(ideal_point)+
             vader_text, 
           data = meta, 
           verbose=TRUE)

saveRDS(k16,"k16_model.RDS")


# THIS MODEL IS RUN ON HPC - AND IN ITERATION 49, THE MODEL CONVERGED.


prep <- estimateEffect(~ author_id + 
                         s(month) + 
                         state +
                         s(author.public_metrics.followers_count)+
                         s(author.public_metrics.tweet_count)+
                         s(ideal_point)+
                         vader_text,
                       k16,
                       meta= meta,
                       uncertainty = "Global")

saveRDS(prep, "k16_prep.RDS")
