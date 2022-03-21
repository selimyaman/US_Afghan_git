#enter bearer token here
twarc2 configure

# then search
twarc2 search --archive --limit 100 --no-context-annotations --start-time 2021-05-01 --end-time 2021-11-18 '(taliban OR taleban OR afghanistan OR afghan OR (Islamic Emirate) OR kabul OR pashtun OR pashto OR kandahar OR pashtuns OR (Ashraf Ghani)) lang:en -is:retweet' twarc2_tweets_half.json
#şurda bitti: Processed 2 months/6 months [17:39:49<22:36:17, 9000252 tweets total]. Yaklaşık 15 saat aldı.

#flatten json file by converting it to csv
twarc2 csv twarc2_tweets_half.json tweets_half.csv
