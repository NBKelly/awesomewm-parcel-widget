## awesomewm-parcel-widget
A widget for monitoring parcels and tracking numbers using the parcelsapp api

## features
* Keep track of incoming parcels
* click on an item to open up detailed tracking information in your browser
![Peek 2023-07-06 19-11](https://github.com/NBKelly/awesomewm-parcel-widget/assets/9095245/2f16397a-833d-43bb-8d87-081bb5648693)

## requisites
This depends on the following things:
* get an api key from https://parcelsapp.com/ (and activate it). This allows you to track up to 10 packages a month on the free tier.
* I use python3
* ~~I'm using pycountry. You may need to install it with `pip3 install pycountry`.~~ I factored this out, you don't need to do this anymore. Later on, I might use pycountry to search input countries and make sure they are iso formatted, but this isn't a priority.

## setup
* clone this repo into .config/awesome/
* edit the config.py (see below)
* include and add the widget in your rc.lua file
* edit the config.py to add your api key and set your default country (where you live)

Note that you **need** to specify the destination country in this api. This defaults to whatever country is selected in config.py, but you can override it for each individual tracking number.

* restart awesome
* click the `edit trackers` option and add some tracking numbers to try them out

note that the format is `tracking number, name, country`. Name and country are optional, the default name is `???` and the default country is whatever is in your config.py

## awesome config
This is subject to change, and might be different for you than it is for me.

* open rc.lua
* import parcelWidget somewhere near the top of your file
```
local parcelWidget = require("parcelWidget.parcels-widget")
```
* call the function somewhere in your layout when the wibar is being created. For me, this comes right after my volumebar and it looks like this:
```
volumebar_widget({
    main_color = '#dcdccc',
    mute_color = '#ff0000',
    width = 80,
    shape = 'powerline',
    margins = 8
}),

parcelsWidget(),  
```

## where did the flags come from?
Here's a good collection of 16x14 flags which follow ISO conventions. This is basically the first worthwhile thing I found on a yandex search. https://archive.org/details/4chan_flags
