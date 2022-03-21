import pandas as pd
import pause
import time
import pkg_resources
pkg_resources.require("tweepy==3.10.0")
import tweepy
import botometer
import csv

data = pd.read_csv('prebot_dataset.csv')

#data = pd.read_csv('tweets_cleaned.csv', on_bad_lines='skip', sep=';')

print("The number of total author id in dataset:", len(data['author.id']),'\n')
print("The number of unique author id in dataset:", len(set(data['author.id'])))

authors = list(data['author.username'].drop_duplicates())

rapidapi_key1 = "ENTER YOUR KEY HERE"
rapidapi_key2 = "ENTER YOUR KEY HERE"
rapidapi_key3 = "ENTER YOUR KEY HERE"
rapidapi_key4 = "ENTER YOUR KEY HERE"

twitter_app_auth = {
    'consumer_key': 'ENTER YOUR KEY HERE',
    'consumer_secret': 'ENTER YOUR KEY HERE',
    'access_token': 'ENTER YOUR KEY HERE',
    'access_token_secret': 'ENTER YOUR KEY HERE',
  }


def bot_users(bom,users):
    for idx in users[:1800]:
        try:
            print('Users remaining:', len(authors))
            s = bom.check_account(idx)['raw_scores']['english']['overall']
            fields=[data[data['author.username'] == idx]['author.id'].values[0],data[data['author.username'] == idx]['author.username'].values[0],data[data['author.username'] == idx]['author.name'].values[0] , s]
            with open(r'Bot_Users.csv', 'a') as f:
                writer = csv.writer(f)
                writer.writerow(fields)
            users.remove(idx)
        except Exception as e:
            with open(r'error_type.csv', 'a') as f:
                writer = csv.writer(f)
                writer.writerow([idx , e])
            users.remove(idx)
            pass
        
print("Starting size of users:", len(authors))
while authors:
    for key in [rapidapi_key1, rapidapi_key2, rapidapi_key3, rapidapi_key4]:
        print("Time --> ",time.strftime("%m/%d/%Y, %H:%M:%S", time.localtime()))
        b = botometer.Botometer(wait_on_ratelimit=True,rapidapi_key=key,**twitter_app_auth)
        bot_users(b, authors)
    print("Remaining of users:", len(authors))
    print("Time (Pause)--> ",time.strftime("%m/%d/%Y, %H:%M:%S", time.localtime()))
    pause.days(1)
