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
* I'm using pycountry. You may need to install it with `pip3 install pycountry`.

## setup
* clone this repo into .config/awesome/
* edit the config.py (see below)
* include and add the widget in your rc.lua file
* edit the config.py to add your api key, then add a tracking number or two to test it out

Note that you **need** to specify the destination country in this api. This defaults to whatever country is selected in config.py, but you can override it for each individual tracking number.

## awesome config
This is subject to change, and might be different for you than it is for me.

* open rc.lua
* import exchangeRates somewhere near the top of your file
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
