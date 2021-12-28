import pandas as pd

data = pd.read_csv('tweets_sample_v2(representative).csv')

locations = ['"location": "{}",'.format(loc) for loc in data['author.location']]
pd.DataFrame(locations).to_csv('location_before.csv', index=False)

twitter_id = [f'"{idx}": '+'{' for idx in data['author.id']]
pd.DataFrame(twitter_id).to_csv('twitter_id_before.csv', index=False)


# code from TIMME --> https://github.com/franklinnwren/TIMME-formatted-location/blob/master/pythonhelper.py

# extract the twitter ids
twitters = []
f = open('twitter_id_before.csv', 'rb')
line = f.readline()
counter = 1
twitters.append((bytes.decode(line)[3:-6], counter))
while line:
    line = f.readline()
    counter += 1
    twitters.append((bytes.decode(line)[3:-6], counter))
f.close()
twitters = twitters[:-1]   #remove the newline at the end

# extract the country names
countries = []
f = open('/content/drive/MyDrive/Research: US Twitter on Afghanistan/LocationExtractor_TIMME/countries.txt', 'rt')
line = f.readline()
countries.append(line[:-1])
while line:
    line = f.readline()
    countries.append(line[:-1])
f.close()
countries = countries[:-1]   #remove the newline at the end


# extract the columns that contain city names, state names (short) and state names (long) from uscities.csv
import csv
with open('/content/drive/MyDrive/Research: US Twitter on Afghanistan/LocationExtractor_TIMME/uscities.csv', 'rt') as csvfile:
    reader = csv.reader(csvfile)
    reference = [(row[1], row[3], row[4]) for row in reader]


# extract the lines that contains self-reported locations and convert them from bytes into strings
locations = []
f = open('location_before.csv', 'rb')
line = f.readline()
locations.append(bytes.decode(line))
while line:
    line = f.readline()
    locations.append(bytes.decode(line))
f.close()
locations = locations[:-1]   #remove the newline at the end
locations = [i.replace('"""','"') for i in locations]
locations = [loc.replace('""','"') for loc in locations]
locations = [l.replace('"\n','\n') for l in locations]


# build a dictionary from states (long) to cities
state_to_city_long = {}
for iter in reference:
    if iter[2] not in state_to_city_long:
        state_to_city_long[iter[2]] = []
    state_to_city_long[iter[2]].append(iter[0])


# build a dictionary from states (short) to cities
state_to_city_short = {}
for iter in reference:
    if iter[1] not in state_to_city_short:
        state_to_city_short[iter[1]] = []
    state_to_city_short[iter[1]].append(iter[0])


# build a dictionary from states (long) to states (short)
state_exchange = {}
for iter in reference:
    if iter[2] not in state_exchange:
        state_exchange[iter[2]] = iter[1]
    else:
        pass


# build our target location list
new_locations = []
counter = 1
for iter in locations:
    if ('"",' in iter):
        new_locations.append(("Unknown", "Unknown", "Unknown", counter))   #if location is empty, skip
        counter += 1
        continue
    if ('D.C' in iter):
        new_locations.append(("Washington", "DC", "United States", counter))  # if location is D.C., add it and skip
        counter += 1
        continue
    found_country_flag = "not found"   #initially, all three labels are set to "not found"
    found_state_flag = "not found"
    found_city_flag = "not found"
    for i in state_to_city_short:
        if i in iter:
            found_country_flag = "found"   #if any state name (short) appears in the text, mark "country" and "state" as "found"
            found_state_flag = "found"
            for j in state_to_city_short[i]:
                if j in iter:
                    if found_city_flag == "found":
                        if new_locations[-1][0] in j:   #if two city names appears in the same line, check whether our current city name is contained in the new city name
                            new_locations = new_locations[:-1]   #if that is the case, remove any city name that has been added before, since we will add the new the city name later
                            counter -= 1
                        else:   #if that is not the case, we do nothing and skip to the next potential city name
                            continue
                    found_city_flag = "found"   #if any city name under that state appears in the text, mark "city" as "found"
                    new_locations.append((j, i, "United States", counter))   #append (city, state, country(USA)) to the new location list
                    counter += 1
            if found_city_flag == "not found":
                new_locations.append(("Unknown", i, "United States", counter))   #city is unknown, append ("Unknown", state, country(USA)) to the new location list
                counter += 1
            break
    if found_country_flag == "found":
        continue   #if we find the country, get to the next line, if not, try the long names of states
    else:
        for i in state_to_city_long:
            if i in iter or i.lower() in iter:
                found_country_flag = "found"   #if any state name (long) appears in the text, mark "country" and "state" as "found"
                found_state_flag = "found"
                for j in state_to_city_long[i]:
                    if j in iter and (j not in i or j == i):
                        if found_city_flag == "found":
                            if new_locations[-1][0] in j:   #if two city names appears in the same line, check whether our current city name is contained in the new city name
                                new_locations = new_locations[:-1]   #if that is the case, remove any city name that has been added before, since we will add the new the city name later
                                counter -= 1
                            else:   #if that is not the case, we do nothing and skip to the next potential city name
                                continue
                        found_city_flag = "found"   #if any city name under that state appears in the text, mark "city" as "found"
                        new_locations.append((j, state_exchange[i], "United States", counter))   #append (city, state, country(USA)) to the new location list
                        counter += 1
                if found_city_flag == "not found":
                    new_locations.append(("Unknown", state_exchange[i], "United States", counter))   #city is unknown, append ("Unknown", state, country(USA)) to the new location list
                    counter += 1
                break
    if found_country_flag == "found":
        continue   #if we find the country, get to the next line, if not, try the country name USA itself and the other countries in the country list
    elif "US" in iter or "U.S." in iter or "United States" in iter or "united states" in iter:   #this is really annoying...
        new_locations.append(("Unknown", "Unknown", "United States", counter))   #city and state is unknown, append ("Unknown", "Unknown", country(USA)) to the new location list
        counter += 1
        found_country_flag = "found"
    else:
        for i in countries:
            if i in iter:
                new_locations.append(("Unknown", "Unknown", i, counter))   #foreign countries
                counter += 1
                found_country_flag = "found"
                break
    if found_country_flag == "found":
        continue
    else:
        new_locations.append(("Unknown", "Unknown", "Unknown", counter))   #we give up...
        counter += 1


counter1 = 0
counter2 = 0
counter3 = 0
for iter in new_locations:
    if iter[2] != "Unknown":
        counter1 += 1
    if iter[1] != "Unknown":
        counter2 += 1
    if iter[0] != "Unknown":
        counter3 += 1
print("Among 90787 locations, " + str(counter1) + " have information about countries, " + str(counter2) + " have information about states, and " + str(counter3) + " have information about cities")


with open('location.csv', 'wt') as out:
    csv_out = csv.writer(out)
    csv_out.writerow(['City', 'State', 'Country', '0'])
    for row in new_locations:
        csv_out.writerow(row)


with open('twitter_id.csv', 'wt') as out:
    csv_out = csv.writer(out)
    csv_out.writerow(['twitter_id', '0'])
    for row in twitters:
        csv_out.writerow(row)