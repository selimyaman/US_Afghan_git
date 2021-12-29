# Location Extraction

As a first step of data cleaning, we wanted to clean all the tweets from non-US countries - that is, if they publicly shared this information on their profile pages. We kept those who say they're from the US and those who do not spesificy anything.

The location extraction method is borrowed from [TIMME](https://github.com/franklinnwren/TIMME-formatted-location). This approach re-formats the public location information into city, state, and country level.

The file `location_extractor.py` takes two pre-written data: `uscities` and `countries`. At the end, it produces two data files: `twitter_id.csv` and `location.csv`. If you want to replicate, you can just remove these output files.

The alternative way of pulling tweets only from the US was to spesifcy `country` information in the search parameters when pulling tweets. However, this limits us only those who share their geo-location information, which is usually very low percentage of Twitter users. 


