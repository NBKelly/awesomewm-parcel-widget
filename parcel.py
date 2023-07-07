import requests
import json
import time
import config
import csv
import os
#import pycountry -- don't need this anymore

trackingUrl = 'https://parcelsapp.com/api/v3/shipments/tracking'


shipment_map = {}
shipment_names = {}
shipment_langs = {}

max_attempts = config.MAX_ATTEMPTS
sleep_time = config.SLEEP_TIME

#print(response)

def load_trackers():
    shipments = []

    ## get the file location and load the csv
    trackers = []

    __location__ = os.path.realpath(
        os.path.join(os.getcwd(), os.path.dirname(__file__)))
    path = os.path.join(__location__, 'trackers.csv')
    if os.path.isfile(path):
        with open(path) as csvfile:
            reader = csv.reader(csvfile, delimiter=',')
            first = True
            for row in reader:
                if first:
                    first = False
                    continue
                if len(row) <= 0:
                    continue
                trackers.append(row)
    ## create the file if it does not exist
    else:
        with open(path, 'a') as f:
            f.write("1. Tracking Number, 2. Name (kind of optional), 3. Destination country (optional - defaults to the country in your config.py), this first line is not processed.")
            #f.close()

    for tracker in trackers:
        shipment = {}
        ### assign a tracking id
        if len(tracker) >= 1:
            shipment['trackingId'] = tracker[0].strip()

        ### assign a name to the parcel if we can
        if len(tracker) >= 2:
            shipment_names[tracker[0]] = tracker[1].strip()
        else:
            shipment_names[tracker[0]] = "???"

        ### assign a destination country to the parcel, or take default from config
        if len(tracker) >= 3:
            shipment['country'] = tracker[2].strip()
        else:
            shipment['country'] = config.COUNTRY

        ### assign language from config
        shipment['language'] = config.LANGUAGE

        shipments.append(shipment)
    return shipments

def format_line(origin, dest, status, days, loc, date, lastupdate, trackingId):
    line = {'origin': origin,
            'destination': dest,
            'currently': status,
            'days-in-transit': days,
            'last location': loc,
            'last date': date,
            'last update': lastupdate,
            'trackingId': trackingId,
            'name': shipment_names[trackingId]
    }

    shipment_map[trackingId] = line
    return line

def process_shipments(data):
    if 'shipments' in data:
        for shipment in data['shipments']:
            #print(json.dumps(shipment, indent=4))
            ## get all the basic information
            origin = shipment['originCode'] if 'origin' in shipment else "xx"
            dest = shipment['destinationCode'] if 'destination' in shipment else "xx"
            status = shipment['status'] if 'status' in shipment else "NOT YET SCANNED"
            trackingId = shipment['trackingId'] if 'trackingId' in shipment else None

            ## see if we can pick up the days in transit
            daysInTransit = "???"
            for attribute in shipment['attributes']:
                if 'l' in attribute and attribute['l'] == "days_transit" and "val" in attribute:
                    daysInTransit = attribute["val"]
                    break
                ## look at the 'last state' and get the location, date and status

            last_loc = None
            last_date = None
            last_status = None

            if "lastState" in shipment:
                last_state = shipment["lastState"]
                #print(last_state)
                last_loc = last_state['location'] if 'location' in last_state else None
                last_date = last_state['date'] if 'date' in last_state else None
                last_status = last_state['status'] if 'status' in last_state else None


            #print(json.dumps(shipment, indent=2))
            format_line(origin, dest, status, daysInTransit, last_loc, last_date, last_status, trackingId)

def process_response(resp, uuid=None, attempts=0):
    if resp.status_code != 200:
        print("err: status code:" + resp.status_code)
        return False
    else:# resp.status_code == 200:
        data = resp.json()
        if 'done' in data and data['done']:
            #print("tracking complete")
            ### print(data)
            process_shipments(data)
        ## If the API is not done yet, we'll need to send another request in soon
        ##   ...for now, I just want to print out the json
        else:
            ## If there's a UUID, fetch it
            #print("not done")
            uuid = data['uuid'] if 'uuid' in data else uuid
            #print(json.dumps(data))
            process_shipments(data)
            if(uuid != None and attempts < max_attempts):
                #print(data)
                #print("sleeping 15 seconds")
                time.sleep(3)
                resp = requests.get(trackingUrl, params={'apiKey': config.API_KEY, 'uuid': uuid})
                process_response(resp, uuid, attempts+1)

            #print(json.dumps(data))

## don't need this anymore, shipment has these isocodes already :)))
#def get_cunt(country):
#    if country is None:
#        return "xx"
#    search = pycountry.countries.search_fuzzy(country)
#    if len(search) == 0:
#        return "xx"
#    return search[0].alpha_2

def output_shipments(shipments):
    for shipment in shipments.items():
        #print(shipment)
        #print(get_cunt(shipment[1]['origin']).lower())
        #print(get_cunt(shipment[1]['destination']).lower())
        #print("?" if shipment[1]['origin'] is None else pycountry.countries.get(name=shipment[1]['origin'])
        print(shipment[1]['origin'].lower())
        print(shipment[1]['destination'].lower())
        print(shipment[1]['name'])
        print(shipment[1]['last update'])
        print(shipment[1]['days-in-transit'])
        print(shipment[1]['trackingId'])
        print(shipment[1]['currently'])


### load tracking numbers from configs
shipments = load_trackers()
### process api
response = requests.post(trackingUrl, json={'apiKey': config.API_KEY, 'shipments': shipments})
process_response(response)
### output
output_shipments(shipment_map)
#print(shipment_map)
