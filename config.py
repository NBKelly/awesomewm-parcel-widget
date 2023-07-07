COUNTRY="New Zealand" # your country here - this is the
                      # default country used for regional tracking information
LANGUAGE="en" # no clue what the api does if you change this

API_KEY='your_key_here'

## The API basically keeps calling until you finish getting all the tracking info.
##  It's probably fine to hard cap it at 15 calls, just incase.
MAX_ATTEMPTS=15 # max number of api calls
SLEEP_TIME=5    # time between api calls
