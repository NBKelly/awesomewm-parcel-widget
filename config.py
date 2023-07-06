COUNTRY="New Zealand" # your country here
LANGUAGE="en" # no clue what the api does if you change this
API_KEY='your_api_key'

MAX_ATTEMPTS=15 # max number of api calls
SLEEP_TIME=5 # time between api calls

### format is [tracking number, name, destination country]
### the second two arguments are optional, but the order is mandatory
### I'll come up with a better way to do this sooner or later :)
TRACKERS=[['tracking_no', "Boxes", "New Zealand"],
          ['tracking_no', 'singles']]
